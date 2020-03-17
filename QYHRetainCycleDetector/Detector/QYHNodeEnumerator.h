//
//  QYHNodeEnumerator.h
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/3/5.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "QYHRetainCycle.h"

QYHNodeEnumerator QYHNodeEnumeratorCreate(QYHNSObject obj);
QYHNodeEnumerator QYHNodeEnumeratorNext(QYHNodeEnumerator node);
void QYHNodeEnumeratorFree(QYHNodeEnumerator obj);

#pragma mark - collection call backs
/**
equal call back for CFSetRef that contains object of type QYHNodeEnumerators
*/
Boolean QYHNodeEnumeratorSetEqualCallBack(const void *value1, const void *value2);

/**
hash call back for CFSetRef that contains object of type QYHNodeEnumerator
*/
CFHashCode QYHNodeEnumeratorSetHashCallBack(const void *value);

/**
equal call back for CFArrayRef that contains object of type QYHNodeEnumerators
*/
Boolean QYHNodeEnumeratorArrayEqualCallBack(const void *value1, const void *value2);

void QYHNodeEnumeratorClearCache();
