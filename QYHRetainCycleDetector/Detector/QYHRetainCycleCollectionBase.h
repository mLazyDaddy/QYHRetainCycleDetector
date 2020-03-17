//
//  QYHRetainCycleCollectionBase.h
//   
//
//  Created by qinyihui on 2020/3/2.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#ifndef QYHRetainCycleCollectionBase_h
#define QYHRetainCycleCollectionBase_h
#import <CoreFoundation/CoreFoundation.h>

Boolean QYHIndexSetEqualCallBack(const void *value1, const void *value2){
    uintptr_t index1 = (uintptr_t)value1;
    uintptr_t index2 = (uintptr_t)value2;
    return index1 == index2;
}

#endif /* QYHRetainCycleCollectionBase_h */
