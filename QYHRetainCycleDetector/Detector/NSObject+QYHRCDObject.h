//
//  NSObject+QYHObject.h
//   
//
//  Created by qinyihui on 2020/1/16.
//  Copyright © 2020 qinyihui. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject(QYHObject)
+ (void)startQYHDetectorRetainCyleTimer;
+ (void)pauseQYHDetectorRetainCyleTimer;
@end

NS_ASSUME_NONNULL_END
