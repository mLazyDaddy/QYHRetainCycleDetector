//
//  QYHRetainCycleDetector.h
//  QYHRetainCycleDetector
//
//  Created by qinyihui on 2020/3/17.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for QYHRetainCycleDetector.
FOUNDATION_EXPORT double QYHRetainCycleDetectorVersionNumber;

//! Project version string for QYHRetainCycleDetector.
FOUNDATION_EXPORT const unsigned char QYHRetainCycleDetectorVersionString[];


// In this header, you should import all the public headers of your framework using statements like #import <QYHRetainCycleDetector/PublicHeader.h>
#import "NSObject+QYHRCDObject.h"
#import "QYHRetainCycleFinder.h"

/**
Retain Cycle Detector is enabled by default in DEBUG builds, but you can also force it in other builds by
uncommenting the line below. Beware, Retain Cycle Detector uses some private APIs that shouldn't be compiled in
production builds.
*/
//#define QYHRCD_ENABLE 1

#ifdef QYHRCD_ENABLE
#define _INTERNAL_QYHRCD_ENABLE QYHRCD_ENABLE
#else
#define _INTERNAL_QYHRCD_ENABLE DEBUG
#endif

@interface QYHRetainCycleDetector : NSObject
+ (void)enable;
+ (void)disable;
+ (void)clearCacheAfterReceivingMemoryWarning;
@end
