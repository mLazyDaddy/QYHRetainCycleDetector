//
//  QYHRetainCycleFinder.h
//  
//
//  Created by qinyihui on 2020/3/17.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <Foundation/Foundation.h>

extern bool QYHDetectRetainCyclesInObject(id obj);

NS_ASSUME_NONNULL_BEGIN

@interface QYHRetainCycleFinder : NSObject
+ (BOOL)detectRetainCyclesInObject:(id)obj;
+ (void)clearCache;
@end

NS_ASSUME_NONNULL_END
