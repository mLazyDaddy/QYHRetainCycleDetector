//
//  QYHIvar.h
//   
//
//  Created by qinyihui on 2020/1/29.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import "QYHRetainCycle.h"

typedef enum{
    QYHIvarTypeNSObject,
    QYHIvarTypeBlock,
    QYHIvarTypeUseless,
}QYHIvarType;

typedef struct QYHIvar_t{
    const char * _Nonnull name;
    ptrdiff_t offset;
    NSUInteger index;
    Ivar _Nonnull ivar;
    QYHIvarType type;
}QYHIvar_t,*QYHIvar;

/**
 * create QYHIvar.
*/
QYHIvar _Nonnull QYHIvarCreate(Ivar _Nonnull ivar);

/**
 * Reads the value of an instance variable in an object.
*
 * @param obj The object containing the instance variable whose value you want to read.
 * @param ivar The Ivar describing the instance variable whose value you want to read.
*
 * @return An instance variable of the object.
 */
CFTypeRef _Nonnull QYHIvarGetVariable(id _Nonnull obj, Ivar _Nonnull ivar);


/**
 * free QYHIvar.
 */
void QYHIvarFree(QYHIvar _Nonnull qyhIvar);

void QYHIvarTrueFree(QYHIvar _Nonnull obj);

void QYHIvarClearCache();
