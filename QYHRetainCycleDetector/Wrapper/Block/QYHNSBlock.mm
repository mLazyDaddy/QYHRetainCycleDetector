//
//  QYHNSBlock.m
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/3/3.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "QYHNSBlock.h"
#import "QYHNSBlockLayout.h"
#import "QYHNSObject.h"

extern QYHNSObject QYHNSObjectCreate(CFTypeRef obj,const char *ivarName,QYHNSObjectType type);
extern void QYHNSObjectFree(QYHNSBlock obj);

QYHNSBlock QYHNSBlockCreate(CFTypeRef obj){
    QYHNSBlock object = QYHNSObjectCreate(obj, NULL, QYHNSObjectTypeBlock);
    object->name = "[BlockReference]";
    return object;
}

CFMutableSetRef QYHGetBlockStrongReferences(void *block){
    CFArrayRef strongLayout = QYHGetBlockStrongLayout(block);
    if (!strongLayout) {
        return nil;
    }
    void **blockReference = (void **)block;
    
    const CFSetCallBacks callBacks = {0,NULL,NULL,NULL,QYHNSObjectSetEqualCallBack,QYHNSObjectSetHashCallBack};
    CFMutableSetRef results = CFSetCreateMutable(NULL, 0, &callBacks);
    
    CFIndex cnt = CFArrayGetCount(strongLayout);
    const void *indices[cnt];
    CFArrayGetValues(strongLayout, CFRangeMake(0, cnt), indices);
    
    for (CFIndex idx = 0; idx < cnt; idx ++) {
        const uintptr_t index = (uintptr_t)indices[idx];
        void **reference = &blockReference[index];
        if (reference && (*reference)) {
            id object = (id)(*reference);
            if (object) {
                CFRetain(object);
                QYHNSBlock wrapper = QYHNSBlockCreate((CFTypeRef)object);
                CFRelease(object);            
                CFSetAddValue(results, wrapper);
            }
        }
        
    }
    CFRelease(strongLayout);
    return results;
}

static Class _BlockClass() {
    static dispatch_once_t onceToken;
      static Class blockClass;
      dispatch_once(&onceToken, ^{
        void (^testBlock)() = [^{} copy];
        blockClass = [testBlock class];
        while(class_getSuperclass(blockClass) && class_getSuperclass(blockClass) != [NSObject class]) {
          blockClass = class_getSuperclass(blockClass);
        }
          CFRelease(testBlock);
      });
      return blockClass;
}

BOOL QYHObjectIsBlock(void *object) {
  Class blockClass = _BlockClass();
  
  Class candidate = object_getClass((__bridge id)object);
  return [candidate isSubclassOfClass:blockClass];
}

