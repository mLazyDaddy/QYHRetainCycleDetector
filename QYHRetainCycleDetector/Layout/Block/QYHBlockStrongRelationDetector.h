//
//  QYHBlockStrongRelationDetector.h
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/2/25.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import <Foundation/Foundation.h>

struct _block_byref_block;
@interface QYHBlockStrongRelationDetector : NSObject
{
  // __block fakery
  void *forwarding;
  int flags;   //refcount;
  int size;
  void (*byref_keep)(struct _block_byref_block *dst, struct _block_byref_block *src);
  void (*byref_dispose)(struct _block_byref_block *);
  void *captured[16];
}

@property (nonatomic, assign, getter=isStrong) BOOL strong;

- (oneway void)trueRelease;

- (void *)forwarding;

@end
