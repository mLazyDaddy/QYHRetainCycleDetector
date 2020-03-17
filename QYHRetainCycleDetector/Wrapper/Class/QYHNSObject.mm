//
//  QYHNSObject.m
//   
//
//  Created by qinyihui on 2020/2/2.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "QYHNSObject.h"
#import "QYHIvar.h"
#import "QYHNSObjectLayout.h"

static const char* kQYHNSObjectKeyCString = "[CollectionKey]";
static const char* kQYHNSObjectValueCString = "[CollectionValue]";
static const char* kQYHNSTimerTargetCString = "[NSTimerTarget]";
static const char* QYHNSTimerInfoCString = "[NSTimerUserInfo]";

static CFMutableArrayRef QYHNSObjectReusedArray = CFArrayCreateMutable(NULL, 0, NULL);
static int QYHNSObjectReusedArrayLastIndex = -1;

static QYH_ALWAYS_INLINE QYHNSObject QYHNSObjectAlloc(){
    if (QYHNSObjectReusedArrayLastIndex < 0) {
        return (QYHNSObject)CFAllocatorAllocate(NULL, sizeof(QYHNSObject_t), 0);
    }else{
        QYHNSObject object = (QYHNSObject)CFArrayGetValueAtIndex(QYHNSObjectReusedArray, QYHNSObjectReusedArrayLastIndex);
        CFArrayRemoveValueAtIndex(QYHNSObjectReusedArray, QYHNSObjectReusedArrayLastIndex);
        QYHNSObjectReusedArrayLastIndex--;
        return object;
    }
}

QYHNSObject QYHNSObjectCreate(CFTypeRef obj,const char *ivarName,QYHNSObjectType type){
    QYHNSObject object = QYHNSObjectAlloc();
    CFRetain(obj);
    object->object = obj;
    object->name = ivarName;
    object->type = type;
    return object;
}

QYHNSObject QYHNSObjectCreate(CFTypeRef obj,const char *ivarName){
    QYHNSObject object = QYHNSObjectCreate(obj,ivarName,QYHNSObjectTypeNormal);
    return object;
}

void QYHNSObjectFree(QYHNSObject obj){
    CFRelease(obj->object);
    obj->object = nil;
    CFArrayAppendValue(QYHNSObjectReusedArray, obj);
    QYHNSObjectReusedArrayLastIndex++;
}

void QYHNSObjectTrueFree(QYHNSObject obj){
    if (obj->object) {
        CFRelease(obj->object);
    }
    CFAllocatorDeallocate(NULL, obj);
}

#pragma mark - collections
static bool objectRetainsEnumerableValues( id obj){
    if ([obj respondsToSelector:@selector(valuePointerFunctions)]) {
        NSPointerFunctions *pointerFunctions = [obj valuePointerFunctions];
        if (pointerFunctions.acquireFunction == NULL) {
            return NO;
        }
        if (pointerFunctions.usesWeakReadAndWriteBarriers) {
            return NO;
        }
    }
    return YES;
}

static bool objectRetainsEnumerableKeys(__unsafe_unretained id obj){
    if ([obj respondsToSelector:@selector(pointerFunctions)]) {
        NSPointerFunctions *pointerFunctions = [obj pointerFunctions];
        if (pointerFunctions.acquireFunction == NULL) {
            return NO;
        }
        if (pointerFunctions.usesWeakReadAndWriteBarriers) {
            return NO;
        }
    }
    if ([obj respondsToSelector:@selector(keyPointerFunctions)]) {
        NSPointerFunctions *pointerFunctions = [obj keyPointerFunctions];
        if (pointerFunctions.acquireFunction == NULL) {
            return NO;
        }
        if (pointerFunctions.usesWeakReadAndWriteBarriers) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - should ignore some NSObjects
static QYH_ALWAYS_INLINE bool shouldIgnoreObj(id obj){
    if ([obj isKindOfClass:[NSString class]]) {
        return true;
    }
    if ([obj isKindOfClass:[NSDate class]]) {
        return true;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return true;
    }
    if ([obj isKindOfClass:[NSBundle class]]) {
        return true;
    }
    if (CFGetRetainCount(obj) > 0xFFFFFFFF) {//It's a loose judgment about taggedPointer
        return true;
    }
    return false;
}

#pragma mark - call back
Boolean QYHNSObjectSetEqualCallBack(const void *value1, const void *value2){
    QYHNSObject object1 = (QYHNSObject)value1;
    QYHNSObject object2 = (QYHNSObject)value2;
    // If one object is xpc_object ,and another is NSObject,CFEqual will call xpc_equal and crash
    return CFEqual(object1->object, object2->object);
}

CFHashCode QYHNSObjectSetHashCallBack(const void *value){    
    return CFHash(((QYHNSObject)value)->object);
}

#pragma mark - strong subobjects
static void getInstancesOfObjectFromIvars(id obj,CFMutableSetRef strongVariables,CFArrayRef ivars){
    CFIndex cnt = 0;
    if (ivars) {
        cnt = CFArrayGetCount(ivars);
    }
    for (int idx = 0; idx< cnt; idx++) {
        QYHIvar wrapper = (QYHIvar)CFArrayGetValueAtIndex(ivars, idx);
        CFTypeRef filed = QYHIvarGetVariable(obj, wrapper->ivar);
        if (filed) {
            CFRetain(filed);
            bool shouldIgnore = shouldIgnoreObj((__bridge id)filed);
            if (shouldIgnore) {
                CFRelease(filed);
                continue;
            }
            QYHNSObject memberObject = QYHNSObjectCreate(filed,wrapper->name);
            CFRelease(filed);
            if (CFSetContainsValue(strongVariables, memberObject)) {
                QYHNSObjectFree(memberObject);
            }else{
                CFSetAddValue(strongVariables, memberObject);//when the user owned the object no longer use it ,he should free it
            }
        }
    }
}

static void getStrongReferenceOfCollection(id obj,Class objClass,CFMutableSetRef strongVariables){
    //obj is collection
    bool retainsKeys = objectRetainsEnumerableKeys(obj);
    bool retainsValues = objectRetainsEnumerableValues(obj);
    
    bool isKeyValued = false;
    if ([objClass instancesRespondToSelector:@selector(objectForKey:)]) {
        isKeyValued = true;
    }
    
    /**
    This codepath is prone to errors. When you enumerate a collection that can be mutated while enumeration
    we fall into risk of crash. To save ourselves from that we will catch such exception and try again.
    We should not try this endlessly, so at some point we will simply give up.
    */
    CFIndex tries = 10;
    for (CFIndex idx = 0; idx < tries; idx++) {
        @try {
            for (id item in obj){
                if (retainsKeys) {
                    QYHNSObject wrapper = QYHNSObjectCreate((__bridge CFTypeRef)item,kQYHNSObjectKeyCString);
                    CFSetAddValue(strongVariables, wrapper);
                }
                if (isKeyValued && retainsValues) {
                    id retainedValue = [obj objectForKey:item];
                    
                    QYHNSObject wrapper = QYHNSObjectCreate((__bridge CFTypeRef)retainedValue,kQYHNSObjectValueCString);
                    CFSetAddValue(strongVariables, wrapper);
                }
            }
        }@catch (NSException *exception) {
            NSLog(@"error %@",exception.description);
            // mutation happened, we want to try enumerating again
            continue;
        }
        break;
    }
}

CFMutableSetRef QYHGetStrongReferenceMemberVars(id obj){
    if (!obj) {
        return NULL;
    }
    
    CFSetCallBacks callBacks = {0,NULL,NULL,NULL,QYHNSObjectSetEqualCallBack,QYHNSObjectSetHashCallBack};    
    CFMutableSetRef strongVariables = CFSetCreateMutable(kCFAllocatorDefault, 0, &callBacks);
    
    Class currentClass = [obj class];
    
    while (currentClass) {
        CFArrayRef ivars = QYHGetStrongReferencesForClass(currentClass);
        getInstancesOfObjectFromIvars(obj,strongVariables, ivars);
        currentClass = class_getSuperclass(currentClass);
    }
    
    Class aCls = [obj class];
    if ([aCls conformsToProtocol:@protocol(NSFastEnumeration)]) {
        getStrongReferenceOfCollection(obj, aCls,strongVariables);
    }
    
    return strongVariables;
}

CFMutableSetRef QYHGetNSTimerStrongReferences(id obj){
    if (!obj) {
        return NULL;
    }
    
    CFSetCallBacks callBacks = {0,NULL,NULL,NULL,NULL,NULL};
    callBacks.equal = QYHNSObjectSetEqualCallBack;
    callBacks.hash = QYHNSObjectSetHashCallBack;
    CFMutableSetRef strongTargets = CFSetCreateMutable(kCFAllocatorDefault, 0, &callBacks);
    
    // Inspired by FBRetainCycleDetactor
    NSTimer *timer = obj;
    if (timer) {
        CFRunLoopTimerContext context;
        CFRunLoopTimerGetContext((CFRunLoopTimerRef)timer,&context);

        // If it has a retain function, let's assume it retains strongly
        if (context.info && context.retain) {
            QYHNSCFTimerInfoStruct infoStruct = *(QYHNSCFTimerInfoStruct *)context.info;
            id target = infoStruct.target;
            if (target) {
                QYHNSObject ocObject = QYHNSObjectCreate((__bridge CFTypeRef)target,kQYHNSTimerTargetCString);
                
                CFSetAddValue(strongTargets, ocObject);
            }
            id userInfo = infoStruct.userInfo;
            if (userInfo) {
                QYHNSObject ocObject = QYHNSObjectCreate((__bridge CFTypeRef)userInfo,QYHNSTimerInfoCString);
                
                CFSetAddValue(strongTargets, ocObject);
            }
        }
    }
    return strongTargets;
}

CFStringRef QYHNSObjectDescription(QYHNSObject obj){
    if (obj->name == nil) {
        CFStringRef description = CFStringCreateWithFormat(NULL, NULL, CFSTR("(0x%lx,%s)"),(uintptr_t)obj->object,object_getClassName((id)obj->object));
        return description;
    }else{
        return CFStringCreateWithFormat(NULL, NULL, CFSTR("%s(0x%lx,%s)"),obj->name,(uintptr_t)obj->object,object_getClassName((id)obj->object));
    }
}

void QYHNSObjectClearCache(){
    for (; QYHNSObjectReusedArrayLastIndex > -1 ; QYHNSObjectReusedArrayLastIndex--) {
        QYHNSObject obj = (QYHNSObject)CFArrayGetValueAtIndex(QYHNSObjectReusedArray, QYHNSObjectReusedArrayLastIndex);
        CFArrayRemoveValueAtIndex(QYHNSObjectReusedArray, QYHNSObjectReusedArrayLastIndex);
        QYHNSObjectTrueFree(obj);
    }
    QYHIvarClearCache();
    QYHClearStrongReferenceIvarsCache();
}
