//
//  NSObject+QYHObject.m
//   
//
//  Created by qinyihui on 2020/1/16.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import "NSObject+QYHRCDObject.h"
#import <objc/runtime.h>
#import <objc/objc.h>
#import <dlfcn.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <pthread.h>
#import <os/lock.h>

#import "QYHRetainCycle.h"
#import "QYHBlockStrongRelationDetector.h"
#import "QYHRetainCycleDetector.h"
#import "QYHRetainCycleFinder.h"

typedef enum : NSUInteger {
    QYH_RCD_LevelNormal = 0,
    QYH_RCD_LevelProbeOnceAndFound,
    QYH_RCD_LevelProbeTwiceAndFound,
    QYH_RCD_LevelProbeOnceAndNotFound,
    QYH_RCD_LevelProbeTwiceAndNotFound
} QYH_RCD_Level;

@implementation NSObject (QYHObject)

//static pthread_key_t QYH_STORE_STRONG_RETURN_ADDRESS_KEY;

static const NSString *kQYHRCDLevelKey = @"kQYHRCDLevelKey";
static NSUInteger QYHRCDLevelCounter = 0;


static const NSUInteger kQYHRCDLevelNormalUpper = 3;
static const NSUInteger kQYHRCDLevelNotFoundUpper = 10;

static const CGFloat kQYHRCDTimerInterval = 3;

static CFMutableSetRef QYHRetainCycleDetectorObjectsCache;
static dispatch_source_t QYHDetectorRetainCyleTimer;
static dispatch_semaphore_t QYHDetectorRetainCycleLock;

#if _INTERNAL_QYHRCD_ENABLE
#pragma mark - init
+(void)load{
    initQYHDetectorRetainCycleObjectsCache();
    initQYHDetectorRetainCycleLock();
    loadRuntimeFunction();
}

static QYH_ALWAYS_INLINE void initQYHDetectorRetainCycleObjectsCache(){
    const CFSetCallBacks cb = {0,QYHCacheSetRetainCallBack,QYHCacheSetReleaseCallBack,NULL, QYHCacheSetEqualCallBack, QYHCacheSetHashCallBack};

    QYHRetainCycleDetectorObjectsCache = CFSetCreateMutable(NULL, 0, &cb);
}

static QYH_ALWAYS_INLINE void initQYHDetectorRetainCycleLock(){
    QYHDetectorRetainCycleLock = dispatch_semaphore_create(1);
}

#pragma mark - runtime intercept
static id(*retainFuncPointer)(id obj);
static void(*releaseFuncPointer)(id obj);
//static id(*autoreleaseFuncPointer)(id obj);

id objc_retain(id obj)
{
    if(!obj)return obj;
    id value = retainFuncPointer(obj);;
    addObjectToCache(obj);
    return value;
}

void objc_storeStrong(id *location, id obj)
{
    id prev = *location;
    if (obj == prev) {
        return;
    }
    objc_retain(obj);
    *location = obj;
    objc_release(prev);
}

id objc_retainBlock(id obj)
{
    return (id)_Block_copy(obj);
}

void objc_release(id obj){
    if(!obj) return;
    removeObjectFromCache(obj);
    releaseFuncPointer(obj);
}

//id objc_autorelease(id obj){
//    if (!obj) return obj;
//
//    if (!autoreleaseFuncPointer) {
//        if (!loadRuntimeFunction()) return obj;
//    }
//    return autoreleaseFuncPointer(obj);
//}
//
//id objc_retainAutorelease(id obj)
//{
//    return objc_autorelease(objc_retain(obj));
//}
//
//id objc_retainAutoreleaseAndReturn(id obj)
//{
//    return objc_retainAutorelease(obj);
//}
//
//id objc_autoreleaseReturnValue(id obj)
//{
//    return objc_autorelease(obj);
//}
//
//// Prepare a value at +0 for return through a +0 autoreleasing convention.
//id objc_retainAutoreleaseReturnValue(id obj)
//{
//    // not objc_autoreleaseReturnValue(objc_retain(obj))
//    // because we don't need another optimization attempt
//    return objc_retainAutoreleaseAndReturn(obj);
//}
//
//// Accept a value returned through a +0 autoreleasing convention for use at +1.
//id objc_retainAutoreleasedReturnValue(id obj)
//{
//    return objc_retain(obj);
//}

#pragma mark - load dyld function
static bool loadRuntimeFunction(){
    void *handle = dlopen("libobjc.A.dylib", RTLD_NOW);
    char *err = dlerror();
    bool success = false;
    
    if(!handle){
        NSLog(@"%s,%s",__func__,"dlopen error");
    }else{
        retainFuncPointer = dlsym(handle, "objc_retain");
        if ((err = dlerror()) != NULL)
        {
            NSLog(@"%s,%s,%s",__func__,"load objc_retain error",err);
            goto finish;
        }
        releaseFuncPointer = dlsym(handle, "objc_release");
        if ((err = dlerror()) != NULL)
        {
            NSLog(@"%s,%s,%s",__func__,"load objc_release error",err);
            goto finish;
        }
//        autoreleaseFuncPointer = dlsym(handle, "objc_autorelease");
//        if ((err = dlerror()) != NULL)
//        {
//            NSLog(@"%s,%s,%s",__func__,"load objc_autorelease error",err);
//            goto finish;
//        }
        
        success = true;
        goto finish;
    }
    finish:
        dlclose(handle);
        return success;;
}

#pragma mark - associatedObject
- (QYH_RCD_Level)getQYH_RCD_CacheLevel{
    return (QYH_RCD_Level)(uintptr_t)objc_getAssociatedObject(self, kQYHRCDLevelKey);
}

- (void)setQYH_RCD_CacheLevel:(QYH_RCD_Level)level{
    objc_setAssociatedObject(self, kQYHRCDLevelKey, (const void *)(uintptr_t)level, OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark - optimize detector
static QYH_ALWAYS_INLINE bool shouldIgnoreObj(__unsafe_unretained id obj){
    if ([obj isKindOfClass:[NSString class]]) {
        return true;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return true;
    }
    if ([obj isKindOfClass:[NSDate class]]) {
        return true;
    }
    if (CFGetRetainCount(obj) > 0xFFFFFFFF) {//It's a loose judgment about taggedPointer
        return true;
    }    
    if ([obj isKindOfClass:[NSBundle class]]) {
        return true;
    }
    if ([obj isKindOfClass:[QYHBlockStrongRelationDetector class]]) {
        return true;
    }
    return false;
}

static QYH_ALWAYS_INLINE void addObjectToCache(__unsafe_unretained id obj){
    if (shouldIgnoreObj(obj)) {
        return;
    }
    qyhRetainCycleLock();
    CFSetAddValue(QYHRetainCycleDetectorObjectsCache, (const void *)obj);
    qyhRetainCycleUnlock();
}

static QYH_ALWAYS_INLINE void removeObjectFromCache(__unsafe_unretained id obj){
    if (!obj) {
        return;
    }
    if (shouldIgnoreObj(obj)) {
        return;
    }
    qyhRetainCycleLock();
    CFSetRemoveValue(QYHRetainCycleDetectorObjectsCache, (const void *)obj);
    qyhRetainCycleUnlock();
}

static const void *QYHCacheSetRetainCallBack(CFAllocatorRef allocator, const void *value){    
    return (const void *)retainFuncPointer(value);
}

static void QYHCacheSetReleaseCallBack(CFAllocatorRef allocator, const void *value){
    releaseFuncPointer(value);
}

static Boolean QYHCacheSetEqualCallBack(const void *value1, const void *value2){
    return CFEqual(value1, value2);
}

static CFHashCode QYHCacheSetHashCallBack(const void *value){
    return CFHash(value);
}

#pragma mark - timer
static QYH_ALWAYS_INLINE void createQYHDetectorRetainCyleTimer(){    
    if (!QYHDetectorRetainCyleTimer) {
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        QYHDetectorRetainCyleTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(QYHDetectorRetainCyleTimer, dispatch_walltime(NULL, 0), kQYHRCDTimerInterval * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(QYHDetectorRetainCyleTimer, ^{
            detectRetainCycle();
        });
    }
}

static void detectRetainCycle(){
    qyhRetainCycleLock();
    
    BOOL foundRetainCycle = false;
    CFIndex cnt = CFSetGetCount(QYHRetainCycleDetectorObjectsCache);
    const void *objects[cnt];
    CFSetGetValues(QYHRetainCycleDetectorObjectsCache, objects);
        
    for (CFIndex idx = 0; idx < cnt; idx ++) {
        __unsafe_unretained id obj = (__bridge id)objects[idx];
        
        QYH_RCD_Level level = [obj getQYH_RCD_CacheLevel];

        BOOL shouldDetect = shouldDetectRetainCycle(level);

        if (shouldDetect) {
            foundRetainCycle = [QYHRetainCycleFinder detectRetainCyclesInObject:obj];
            updateQYH_RCD_CacheLevel(obj,level,foundRetainCycle);
        }
    }
    if (QYHRCDLevelCounter < NSUIntegerMax) {
        QYHRCDLevelCounter ++;
    }else{
        QYHRCDLevelCounter = 0;
    }
    qyhRetainCycleUnlock();
}

static QYH_ALWAYS_INLINE BOOL shouldDetectRetainCycle(QYH_RCD_Level level){
    BOOL shouldDetect = false;
    if (level == QYH_RCD_LevelNormal) {
        shouldDetect = true;
    }else{
        if ((level == QYH_RCD_LevelProbeOnceAndNotFound || level == QYH_RCD_LevelProbeOnceAndFound) && ((QYHRCDLevelCounter % kQYHRCDLevelNormalUpper) == 0 )) {
            // If there is not retain cycle in the object after probing once,the next probing should be later.
            // If there is retain cycle in the object after probing once,the next probing should be later too.
            shouldDetect = true;
        }else if ((level == QYH_RCD_LevelProbeTwiceAndNotFound || level == QYH_RCD_LevelProbeTwiceAndFound) && ((QYHRCDLevelCounter % kQYHRCDLevelNotFoundUpper) == 0)){
            // if there is not retain cycle in the object after probing twice,the next probing should be later than QYH_RCD_LevelProbeTwiceAndNotFound.
            // If there are both retain cycle in the object after probing twice,the next probing should be later too.
            shouldDetect = true;
        }
    }
    return shouldDetect;
}

static QYH_ALWAYS_INLINE void updateQYH_RCD_CacheLevel(id obj,QYH_RCD_Level level,bool foundRetainCycle){
    if (foundRetainCycle) {
        if (level == QYH_RCD_LevelProbeOnceAndFound || level == QYH_RCD_LevelProbeTwiceAndFound) {
            // If there is retain cycle in the object after probing twice,the next probing should be later than QYH_RCD_LevelProbeOnceAndFound.
            [obj setQYH_RCD_CacheLevel:QYH_RCD_LevelProbeTwiceAndFound];            ;
        }else{
            // If there are both retain cycle in the object after probing once,the next probing should be later.
            [obj setQYH_RCD_CacheLevel:QYH_RCD_LevelProbeOnceAndFound];
        }
    }else{
        if (level == QYH_RCD_LevelNormal) {
            // If there is not retain cycle in the object after probing once,the next probing should be later.
            [obj setQYH_RCD_CacheLevel:QYH_RCD_LevelProbeOnceAndNotFound];
        }else if (level == QYH_RCD_LevelProbeOnceAndNotFound){
            // if there is not retain cycle in the object after probing twice,the next probing should be later than previous one.
            [obj setQYH_RCD_CacheLevel:QYH_RCD_LevelProbeTwiceAndNotFound];
        }
    }
}

static void qyhRetainCycleLock(){
    dispatch_semaphore_wait(QYHDetectorRetainCycleLock, DISPATCH_TIME_FOREVER);
}

static void qyhRetainCycleUnlock(){
    dispatch_semaphore_signal(QYHDetectorRetainCycleLock);
}
#endif

+ (void)startQYHDetectorRetainCyleTimer{
#if _INTERNAL_QYHRCD_ENABLE
    createQYHDetectorRetainCyleTimer();
    dispatch_resume(QYHDetectorRetainCyleTimer);
#endif
}

+ (void)pauseQYHDetectorRetainCyleTimer{
#if _INTERNAL_QYHRCD_ENABLE
    dispatch_suspend(QYHDetectorRetainCyleTimer);
#endif
}
@end

