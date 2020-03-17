//
//  QYHRetainCycleGragh.h
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/2/24.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

typedef struct QYHRetainCycleGraph_t{
    CFStringRef description;
    CFStringRef path;
}QYHRetainCycleGraph_t,*QYHRetainCycleGraph;

QYHRetainCycleGraph QYHRetainCycleGraphCreate(CFStringRef description,CFStringRef path);

/**
 * free QYHRetainCycleGraph.
 */
void QYHRetainCycleGraphFree(QYHRetainCycleGraph gragh);

Boolean QYHRetainCycleGraphSetEqualCallBack(const void *value1, const void *value2);
CFHashCode QYHRetainCycleGraphSetHashCallBack(const void *value);
