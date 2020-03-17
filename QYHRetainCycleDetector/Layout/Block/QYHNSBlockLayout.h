//
//  QYHNSBlockLayout.h
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/3/2.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "QYHRetainCycle.h"

CFArrayRef QYHGetBlockStrongLayout(void *block);
