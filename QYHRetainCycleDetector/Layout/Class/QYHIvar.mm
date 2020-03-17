//
//  QYHIvar.m
//   
//
//  Created by qinyihui on 2020/1/29.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import "QYHIvar.h"

static CFMutableArrayRef QYHIvarReusedArray = CFArrayCreateMutable(NULL, 0, NULL);
static int QYHIvarReusedArrayLastIndex = -1;

static QYH_ALWAYS_INLINE QYHIvarType getQYHIvarType(Ivar ivar){
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (!typeEncoding) {
        return QYHIvarTypeUseless;
    }

    if (typeEncoding[0] == '@') {
        if (strncmp(typeEncoding, "@\"NSString\"", 11) == 0) {
            return QYHIvarTypeUseless;
        }
        if (strncmp(typeEncoding, "@\"NSNumber\"", 11) == 0) {
            return QYHIvarTypeUseless;
        }
        if (strncmp(typeEncoding, "@\"NSDate\"", 11) == 0) {
            return QYHIvarTypeUseless;
        }
        if (strncmp(typeEncoding, "@\"NSObject<OS_xpc_object>\"", 28) == 0) {
            // When use CFEqual to xpc_object,will call xpc_equal.If another object is not xpc_object,it will crash.I don't know why and xpc_object is useless in detecting retaincyle.
            return QYHIvarTypeUseless;
        }
        return QYHIvarTypeNSObject;
    }
    if (strncmp(typeEncoding, "@?", 2) == 0) {
        return QYHIvarTypeBlock;
    }
    return QYHIvarTypeUseless;
}

static QYH_ALWAYS_INLINE QYHIvar QYHIvarAlloc(){
    if (QYHIvarReusedArrayLastIndex < 0) {
        return (QYHIvar)CFAllocatorAllocate(NULL, sizeof(QYHIvar_t), 0);
    }else{
        QYHIvar obj = (QYHIvar)CFArrayGetValueAtIndex(QYHIvarReusedArray, QYHIvarReusedArrayLastIndex);
        CFArrayRemoveValueAtIndex(QYHIvarReusedArray, QYHIvarReusedArrayLastIndex);
        QYHIvarReusedArrayLastIndex--;
        return obj;
    }
}

QYHIvar QYHIvarCreate(Ivar ivar){
    QYHIvar obj = QYHIvarAlloc();
    obj->ivar = ivar;
    obj->offset = ivar_getOffset(ivar);
    obj->index = obj->offset / sizeof(void *);
    obj->name = ivar_getName(ivar);
    obj->type = getQYHIvarType(ivar);
    return obj;
}

CFTypeRef QYHIvarGetVariable(id obj, Ivar ivar){
    return  (__bridge CFTypeRef)object_getIvar(obj, ivar);
}

void QYHIvarFree(QYHIvar obj){
    CFArrayAppendValue(QYHIvarReusedArray, obj);    
    QYHIvarReusedArrayLastIndex ++;
}

void QYHIvarTrueFree(QYHIvar obj){
    CFAllocatorDeallocate(NULL, obj);
}

void QYHIvarClearCache(){
    for (; QYHIvarReusedArrayLastIndex > -1 ; QYHIvarReusedArrayLastIndex--) {
        QYHIvar obj = (QYHIvar)CFArrayGetValueAtIndex(QYHIvarReusedArray, QYHIvarReusedArrayLastIndex);
        CFArrayRemoveValueAtIndex(QYHIvarReusedArray, QYHIvarReusedArrayLastIndex);
        QYHIvarTrueFree(obj);
    }
}
