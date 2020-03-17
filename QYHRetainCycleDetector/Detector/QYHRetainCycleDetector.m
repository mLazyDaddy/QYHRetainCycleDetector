//
//  QYHRetainCycleDetector.mm
//   
//
//  Created by qinyihui on 2020/2/5.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "QYHRetainCycleDetector.h"

@implementation QYHRetainCycleDetector
+ (void)enable{
    [self startQYHDetectorRetainCyleTimer];
}

+ (void)disable{
    [self startQYHDetectorRetainCyleTimer];
}

+ (void)clearCacheAfterReceivingMemoryWarning{
#if _INTERNAL_QYHRCD_ENABLE
    [QYHRetainCycleFinder clearCache];
#endif
}
@end

