//
//  QYHNSBlock.h
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/3/3.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "QYHRetainCycle.h"

/**
 * create QYHNSBlock
 * @return A new QYHNSBlock
 * @param obj A CFTypeRef representing NSObject referenced by block
*/
QYHNSBlock QYHNSBlockCreate(CFTypeRef obj);


CFMutableSetRef QYHGetBlockStrongReferences(void *block);

BOOL QYHObjectIsBlock(void *object);
