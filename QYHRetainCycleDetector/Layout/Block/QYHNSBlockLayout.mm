//
//  QYHNSBlockLayout.mm
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/3/2.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import "QYHNSBlockLayout.h"
#import "QYHBlockStrongRelationDetector.h"

CFArrayRef QYHGetBlockStrongLayout(void *block) {
    struct QYHBlockLiteral *blockLiteral = (QYHBlockLiteral *)block;

    //copy from https://github.com/facebook/FBRetainCycleDetector
    
    /**
     BLOCK_HAS_CTOR - Block has a C++ constructor/destructor, which gives us a good chance it retains
     objects that are not pointer aligned, so omit them.

     !BLOCK_HAS_COPY_DISPOSE - Block doesn't have a dispose function, so it does not retain objects and
     we are not able to blackbox it.
     */
    if ((blockLiteral->flags & BLOCK_HAS_CTOR)
        || !(blockLiteral->flags & BLOCK_HAS_COPY_DISPOSE)) {
      return nil;
    }

    void (*dispose_helper)(void *src) = blockLiteral->descriptor->dispose_helper;
    const size_t ptrSize = sizeof(void *);

    // Figure out the number of pointers it takes to fill out the object, rounding up.
    const size_t elements = (blockLiteral->descriptor->size + ptrSize - 1) / ptrSize;

    // Create a fake object of the appropriate length.
    void *obj[elements];
    void *detectors[elements];

    for (size_t i = 0; i < elements; ++i) {
        QYHBlockStrongRelationDetector *detector = [[QYHBlockStrongRelationDetector alloc] init];
        obj[i] = detectors[i] = detector;
    }

    @autoreleasepool {
      dispose_helper(obj);
    }

    // Run through the release detectors and add each one that got released to the object's
    // strong ivar layout.
    CFMutableArrayRef layout = CFArrayCreateMutable(NULL, elements, NULL);

    for (size_t idx = 0; idx < elements; ++idx) {
      QYHBlockStrongRelationDetector *detector = (QYHBlockStrongRelationDetector *)(detectors[idx]);
      if (detector.isStrong) {
          CFArrayAppendValue(layout, (const void *)(uintptr_t)idx);
      }

      // Destroy detectors
      [detector trueRelease];
    }

    return layout;
}
