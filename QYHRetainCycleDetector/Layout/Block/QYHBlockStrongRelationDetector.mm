//
//  QYHBlockStrongRelationDetector.c
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/2/25.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import <objc/runtime.h>

#import "QYHBlockStrongRelationDetector.h"

static void byref_keep_nop(struct _block_byref_block *dst, struct _block_byref_block *src) {}
static void byref_dispose_nop(struct _block_byref_block *param) {}

@implementation QYHBlockStrongRelationDetector

- (oneway void)release
{
  _strong = YES;
}

- (id)retain
{
  return self;
}

+ (id)alloc
{
  QYHBlockStrongRelationDetector *obj = [super alloc];

  // Setting up block fakery
  obj->forwarding = obj;
  obj->byref_keep = byref_keep_nop;
  obj->byref_dispose = byref_dispose_nop;

  return obj;
}

- (oneway void)trueRelease
{
  [super release];
}

- (void *)forwarding
{
  return self->forwarding;
}

@end




