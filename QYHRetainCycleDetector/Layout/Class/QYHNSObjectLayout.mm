//
//  QYHNSObjectLayout.mm
//  
//
//  Created by qinyihui on 2020/2/29.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import "QYHRetainCycleCollectionBase.h"
#include "QYHNSObjectLayout.h"
#import "QYHIvar.h"

static void QYHIvarsCacheDictValueReleaseCallBack(CFAllocatorRef allocator, const void *value){
    CFArrayRef ivars = (CFArrayRef)value;
    for (int idx = 0; idx <CFArrayGetCount(ivars); idx++) {
        QYHIvar wrapper = (QYHIvar)CFArrayGetValueAtIndex(ivars, idx);
        QYHIvarTrueFree(wrapper);
    }
    CFRelease(ivars);
}

static const CFDictionaryValueCallBacks kQYHIvarsCacheDictValueCallBacks = {0,NULL,QYHIvarsCacheDictValueReleaseCallBack,NULL,NULL};
static CFMutableDictionaryRef QYHStrongReferenceIvarsCache = CFDictionaryCreateMutable(NULL, 0, NULL, &kQYHIvarsCacheDictValueCallBacks);

#pragma mark - strong references layout
/**
@return Index of the first ivar for a given class
*/
static QYH_ALWAYS_INLINE unsigned getIvarStartIndex(__unsafe_unretained Class cls){
    unsigned startIndex = 1;
    unsigned count;
    Ivar* ivars= class_copyIvarList(cls, &count);
    if (count > 0) {
        ptrdiff_t offset = ivar_getOffset(ivars[0]);
        startIndex = offset / sizeof(void *);
    }
    free(ivars);
    return startIndex;
}

/**
 @return A set of indices will contain all strong ivar layouts for a given layout
 */
static CFSetRef geStrongIvarLayoutIndex(NSUInteger startIndex, const uint8_t *layout){
    CFSetCallBacks indicesCallBacks = {0,NULL,NULL,NULL,QYHIndexSetEqualCallBack,NULL};
    CFMutableSetRef indexSet = CFSetCreateMutable(NULL, 0, &indicesCallBacks);
    if (!layout) {
        return indexSet;
    }
    
    uint8_t byte;
    NSUInteger currentIndex = startIndex;
    while((byte = *layout++)){
        unsigned upperNibble = (byte >> 4);
        unsigned lowerNibble = (byte & 0x0F);
        currentIndex += upperNibble;
        unsigned len = currentIndex + lowerNibble;
        for (CFIndex idx = currentIndex;idx < len; idx++) {
            CFSetAddValue(indexSet, (const void *)(uintptr_t)idx);
        }
        currentIndex += lowerNibble;
    }
    return indexSet;
}

/**
@return An array of objects of type QYHIvar representing Ivar  declared by the class. Any instance variables declared by superclasses are not included.
*/
static CFArrayRef getReferencesForClass(__unsafe_unretained Class cls){
    CFMutableArrayRef result = CFArrayCreateMutable(NULL, 0, NULL);
    unsigned int count;
    Ivar* ivars= class_copyIvarList(cls, &count);
    for (unsigned int i = 0; i< count; i++) {
        Ivar ivar = ivars[i];
        QYHIvar wrapper = QYHIvarCreate(ivar);//when no longer use it,should free it
        if (wrapper->type != QYHIvarTypeUseless) {
            CFArrayAppendValue(result, wrapper);
        }else{
            QYHIvarFree(wrapper);
        }
    }
    free(ivars);
    
    return result;
}


CFArrayRef QYHGetStrongReferencesForClass( Class cls){
    CFArrayRef cache = (CFArrayRef)CFDictionaryGetValue(QYHStrongReferenceIvarsCache, (void *)cls);
    if (cache) {
        return cache;
    }
    
    if (class_isMetaClass(cls)) {
        return nil;
    }
    
    const uint8_t *strongLayout = class_getIvarLayout(cls);
    if(!strongLayout){
        return nil;
    }
    
    NSUInteger startIndex = getIvarStartIndex(cls);
    
    CFSetRef parseLayout =  geStrongIvarLayoutIndex(startIndex, strongLayout);
    CFArrayRef ivars = getReferencesForClass(cls);
    CFMutableArrayRef result = CFArrayCreateMutable(NULL, 0, NULL);
    for (int idx = 0; idx <CFArrayGetCount(ivars); idx++) {
        QYHIvar wrapper = (QYHIvar)CFArrayGetValueAtIndex(ivars, idx);
        if (CFSetContainsValue(parseLayout, (const void *)(uintptr_t)wrapper->index)) {
            CFArrayAppendValue(result,wrapper);
        }else{
            QYHIvarFree(wrapper);
        }
    }
    CFRelease(ivars);
    CFRelease(parseLayout);
    
    CFDictionarySetValue(QYHStrongReferenceIvarsCache, (const void *)cls, (const void *)result);
    
    return result;
}

void QYHClearStrongReferenceIvarsCache(){
    CFDictionaryRemoveAllValues(QYHStrongReferenceIvarsCache);
}
