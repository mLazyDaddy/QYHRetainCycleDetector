//
//  QYHRetainCycleFinder.m
//  
//
//  Created by qinyihui on 2020/3/17.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import "QYHRetainCycleFinder.h"
#import "QYHRetainCycle.h"
#import "QYHNSObject.h"
#import "QYHNSBlock.h"
#import "QYHRetainCycleGragh.h"
#import "QYHNodeEnumerator.h"

@implementation QYHRetainCycleFinder

static const NSUInteger kQYHMaxDetectDepth = 10;
static CFMutableSetRef QYHRetainCycleGraghs;

static CFMutableSetRef QYHRCDVisitedObjects;
static CFMutableArrayRef QYHRCDStack;

#pragma mark - should ignore some NSObjects
static QYH_ALWAYS_INLINE bool shouldIgnoreObj(__unsafe_unretained id obj){
    if ([obj isKindOfClass:[NSString class]]) {
        return true;
    }
    if ([obj isKindOfClass:[NSDate class]]) {
        return true;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return true;
    }
    if (CFGetRetainCount(obj) > 0xFFFFFFFF) {//It's a loose judgment about taggedPointer
        return true;
    }
    if ([obj isKindOfClass:[NSBundle class]]) {
        return true;
    }
    return false;
}

#pragma mark - CFArray helper
void removeCFArrayLastObject(CFMutableArrayRef array){
    if (!array) {
        return;
    }
    
    CFIndex cnt = CFArrayGetCount(array);
    if (cnt > 0) {
        CFArrayRemoveValueAtIndex(array, cnt - 1);
    }
}

static const void *getCFArrayLastObject(CFMutableArrayRef array){
    if (!array) {
        return nil;
    }
    
    CFIndex cnt = CFArrayGetCount(array);
    if (cnt > 0) {
        return CFArrayGetValueAtIndex(array, cnt - 1);
    }else{
        return nil;
    }
}

static void initialize(){
    CFSetCallBacks callBacks = {0,NULL,NULL,NULL,QYHRetainCycleGraphSetEqualCallBack,QYHRetainCycleGraphSetHashCallBack};
    QYHRetainCycleGraghs = CFSetCreateMutable(NULL, 0, &callBacks);
    
    CFSetCallBacks QYHRCDVisitedObjectsCallBacks = {0,NULL,NULL,NULL,QYHNodeEnumeratorSetEqualCallBack,QYHNodeEnumeratorSetHashCallBack};
    QYHRCDVisitedObjects = CFSetCreateMutable(kCFAllocatorDefault, kQYHMaxDetectDepth, &QYHRCDVisitedObjectsCallBacks);
    
    CFArrayCallBacks QYHRCDStackCallBacks =  {0,NULL,NULL,NULL,QYHNodeEnumeratorArrayEqualCallBack};
    QYHRCDStack = CFArrayCreateMutable(kCFAllocatorDefault, kQYHMaxDetectDepth, &QYHRCDStackCallBacks);
}

#pragma mark -
#pragma mark detect retain cycle
static void recordRetainCycle(QYHNodeEnumerator node,CFMutableArrayRef stack){
    CFMutableStringRef description = CFStringCreateMutable(NULL, 0);
    CFMutableStringRef path = CFStringCreateMutable(NULL, 0);
    CFStringAppend(description, CFSTR("RetainCycle path::"));
    
    CFIndex cnt = CFArrayGetCount(stack);
    CFIndex idx = CFArrayGetFirstIndexOfValue(stack, CFRangeMake(0, cnt), node);
    assert(idx != kCFNotFound);
    for (; idx < cnt; idx++) {
        QYHNodeEnumerator item = (QYHNodeEnumerator)CFArrayGetValueAtIndex(stack, idx);
        CFStringAppendFormat(path, NULL, CFSTR("0x%ld->"),uintptr_t(item->object->object));
        
        CFStringRef objectDesc = QYHNSObjectDescription(item->object);
        CFStringAppendFormat(description, NULL, CFSTR("%@->"),objectDesc);
        CFRelease(objectDesc);
    }
    CFStringRef nodeObjectDesc = QYHNSObjectDescription(node->object);
    CFStringAppendFormat(description, NULL, CFSTR("%@"),nodeObjectDesc);
    CFRelease(nodeObjectDesc);
    
    CFStringAppendFormat(path, NULL, CFSTR("0x%ld"),uintptr_t(node->object->object));
    
    QYHRetainCycleGraph gragh = QYHRetainCycleGraphCreate(description, path);
    if (CFSetContainsValue(QYHRetainCycleGraghs, gragh)) {
        QYHRetainCycleGraphFree(gragh);
        return;
    }else{
        CFSetAddValue(QYHRetainCycleGraghs, gragh);
        NSLog(@"%@",description);
    }
}

static BOOL findRetainCyclesInObject(QYHNodeEnumerator node){
    CFArrayAppendValue(QYHRCDStack, node);
    CFSetAddValue(QYHRCDVisitedObjects, node);
    
    BOOL foundRetainCycle = false;
    
    while (CFArrayGetCount(QYHRCDStack) > 0) {
        QYHNodeEnumerator top = (QYHNodeEnumerator)getCFArrayLastObject(QYHRCDStack);
        QYHNodeEnumerator firstAdjacent = QYHNodeEnumeratorNext(top);
        
        if (firstAdjacent) {
            if (CFSetContainsValue(QYHRCDVisitedObjects, firstAdjacent)) {
                foundRetainCycle = true;
                                
                recordRetainCycle(firstAdjacent,QYHRCDStack);
                                
                QYHNodeEnumeratorFree(firstAdjacent);
                
                removeCFArrayLastObject(QYHRCDStack);
                CFSetRemoveValue(QYHRCDVisitedObjects, top);
                QYHNodeEnumeratorFree(top);
                
            }else{
                if (CFArrayGetCount(QYHRCDStack) < kQYHMaxDetectDepth) {
                    CFSetAddValue(QYHRCDVisitedObjects, firstAdjacent);
                    CFArrayAppendValue(QYHRCDStack, firstAdjacent);
                }else{
                    QYHNodeEnumeratorFree(firstAdjacent);
                    
                    removeCFArrayLastObject(QYHRCDStack);
                    CFSetRemoveValue(QYHRCDVisitedObjects, top);
                    QYHNodeEnumeratorFree(top);
                }
            }
        }else{
            removeCFArrayLastObject(QYHRCDStack);
            CFSetRemoveValue(QYHRCDVisitedObjects, top);
            QYHNodeEnumeratorFree(top);
        }
    }
    
    return foundRetainCycle;
}

+ (BOOL)detectRetainCyclesInObject:(id)obj{
    if (!obj) {
        return false;;
    }
    if (shouldIgnoreObj(obj)) {
        return false;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initialize();
    });
    
    QYHNSObject wrapper = QYHNSObjectCreate((__bridge CFTypeRef)obj,NULL);
    QYHNodeEnumerator node = QYHNodeEnumeratorCreate(wrapper);
    return findRetainCyclesInObject(node);
}

+ (void)clearCache{
    QYHNodeEnumeratorClearCache();
}

@end
