//
//  QYHNodeEnumerator.m
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/3/5.
//  Copyright © 2020 qinyihui. All rights reserved.
//
#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import <Foundation/Foundation.h>

#import "QYHNodeEnumerator.h"
#import "QYHNSObject.h"
#import "QYHNSBlock.h"

static CFMutableArrayRef QYHNodeEnumeratorReusedArray = CFArrayCreateMutable(NULL, 0, NULL);
static int QYHNodeEnumeratorReusedArrayLastIndex = -1;

/**
@return An array of objects will have all strong references objects the given object has
*/
static CFSetRef getStrongReferencesForInstance(id obj);

static QYH_ALWAYS_INLINE QYHNodeEnumerator QYHNodeEnumeratorAlloc(){
    if (QYHNodeEnumeratorReusedArrayLastIndex < 0) {
        return (QYHNodeEnumerator)CFAllocatorAllocate(NULL, sizeof(QYHNodeEnumerator_t), 0);
    }else{
        QYHNodeEnumerator object = (QYHNodeEnumerator)CFArrayGetValueAtIndex(QYHNodeEnumeratorReusedArray, QYHNodeEnumeratorReusedArrayLastIndex);
        CFArrayRemoveValueAtIndex(QYHNodeEnumeratorReusedArray, QYHNodeEnumeratorReusedArrayLastIndex);
        QYHNodeEnumeratorReusedArrayLastIndex--;
        return object;
    }
}

QYHNodeEnumerator QYHNodeEnumeratorCreate(QYHNSObject obj){
    QYHNodeEnumerator node = QYHNodeEnumeratorAlloc();
    node->object = obj;
    node->references = NULL;
    node->size = 0;
    node->currentIndex = 0;
    return node;
}

void QYHNodeEnumeratorFree(QYHNodeEnumerator obj){
    CFArrayAppendValue(QYHNodeEnumeratorReusedArray, obj);
    QYHNodeEnumeratorReusedArrayLastIndex++;
    if (obj->references) {
        for (int idx = obj->currentIndex; idx <obj->size; idx ++) {
            QYHNSObjectFree((QYHNSObject)obj->references[idx]);
        }
        obj->currentIndex = obj->size;
        CFAllocatorDeallocate(NULL, obj->references);
        obj->references = nil;
    }
    if (obj->object) {
        QYHNSObjectFree(obj->object);
        obj->object = nil;
    }
}

void QYHNodeEnumeratorTrueFree(QYHNodeEnumerator obj){
    if (obj->references) {
        for (int idx = obj->currentIndex; idx <obj->size; idx ++) {
            QYHNSObjectFree((QYHNSObject)obj->references[idx]);
        }
        obj->currentIndex = obj->size;
        CFAllocatorDeallocate(NULL, obj->references);
    }
    if (obj->object) {
        QYHNSObjectTrueFree(obj->object);
    }
    CFAllocatorDeallocate(NULL, obj);
}

QYHNodeEnumerator QYHNodeEnumeratorNext(QYHNodeEnumerator node){
    if (!node->object) {
        return nil;
    }
    if (!node->references) {
        CFSetRef strongReferences = getStrongReferencesForInstance((id)node->object->object);
        if (strongReferences) {
            int cnt = (int)CFSetGetCount(strongReferences);
            void** values = (void**)CFAllocatorAllocate(NULL, sizeof(void *) * cnt, 0);
            CFSetGetValues(strongReferences, (const void **)values);
            node->references = (const void**)values;
            node->size = cnt;
            node->currentIndex = 0;
            CFRelease(strongReferences);
        }        
    }
    
    if (node->currentIndex < node->size) {
        QYHNSObject obj = (QYHNSObject)node->references[node->currentIndex];
        node->currentIndex++;
        return QYHNodeEnumeratorCreate(obj);
    }else{
        return nil;
    }
}

/**
@return An array of objects will have all strong references objects the given object has
*/
static CFSetRef getStrongReferencesForInstance(id obj){
    if (!obj) {
        return nil;
    }
    if ([obj isKindOfClass:[NSTimer class]]) {
        return QYHGetNSTimerStrongReferences(obj);
    }
    else if (QYHObjectIsBlock(obj)){
        return QYHGetBlockStrongReferences(obj);
    }
    else{
        return QYHGetStrongReferenceMemberVars(obj);
    }
}

#pragma mark - collection call backs
Boolean QYHNodeEnumeratorSetEqualCallBack(const void *value1, const void *value2){
    QYHNodeEnumerator object1 = (QYHNodeEnumerator)value1;
    QYHNodeEnumerator object2 = (QYHNodeEnumerator)value2;
    return CFEqual(object1->object->object, object2->object->object);
}

CFHashCode QYHNodeEnumeratorSetHashCallBack(const void *value){
    QYHNodeEnumerator object = (QYHNodeEnumerator)value;
    return CFHash(object->object->object);
}

Boolean QYHNodeEnumeratorArrayEqualCallBack(const void *value1, const void *value2){
    QYHNodeEnumerator object1 = (QYHNodeEnumerator)value1;
    QYHNodeEnumerator object2 = (QYHNodeEnumerator)value2;
    return CFEqual(object1->object->object, object2->object->object);
}

void QYHNodeEnumeratorClearCache(){
    for (; QYHNodeEnumeratorReusedArrayLastIndex > -1 ; QYHNodeEnumeratorReusedArrayLastIndex--) {
        QYHNodeEnumerator obj = (QYHNodeEnumerator)CFArrayGetValueAtIndex(QYHNodeEnumeratorReusedArray, QYHNodeEnumeratorReusedArrayLastIndex);
        CFArrayRemoveValueAtIndex(QYHNodeEnumeratorReusedArray, QYHNodeEnumeratorReusedArrayLastIndex);
        QYHNodeEnumeratorTrueFree(obj);
    }
    QYHNSObjectClearCache();
}
