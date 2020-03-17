//
//  QYHRetainCycleGragh.m
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/2/24.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import "QYHRetainCycleGragh.h"

QYHRetainCycleGraph QYHRetainCycleGraphCreate(CFStringRef description,CFStringRef path){
    QYHRetainCycleGraph obj = (struct QYHRetainCycleGraph_t*)calloc(sizeof(QYHRetainCycleGraph_t),1);
    obj->description = description;
    obj->path = path;
    return obj;
}

void QYHRetainCycleGraphFree(QYHRetainCycleGraph gragh){
    if (gragh->description) {
        CFRelease(gragh->description);
    }
    if (gragh->path) {
        CFRelease(gragh->path);
    }
    free(gragh);
}

#pragma mark - collection call backs
Boolean QYHRetainCycleGraphSetEqualCallBack(const void *value1, const void *value2){
    QYHRetainCycleGraph object1 = (QYHRetainCycleGraph)value1;
    QYHRetainCycleGraph object2 = (QYHRetainCycleGraph)value2;
    CFComparisonResult result = CFStringCompare(object1->path, object2->path, kCFCompareCaseInsensitive);
    if (result == kCFCompareEqualTo) {
        return true;
    }else{
        return false;
    }
}

CFHashCode QYHRetainCycleGraphSetHashCallBack(const void *value){
    return CFHash(((QYHRetainCycleGraph)value)->path);
}
