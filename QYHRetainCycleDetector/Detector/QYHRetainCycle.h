//
//  QYHRetainCycle.h
//   
//
//  Created by qinyihui on 2020/2/13.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#ifndef QYHRetainCycle_h
#define QYHRetainCycle_h

#define QYH_ALWAYS_INLINE inline __attribute__((always_inline))

typedef struct {
  long _unknown; // This is always 1
  id target;
  SEL selector;
  NSDictionary *userInfo;
} QYHNSCFTimerInfoStruct;

typedef enum : short {
    QYHNSObjectTypeNormal = 0,
    QYHNSObjectTypeBlock = 1,
} QYHNSObjectType;

typedef struct QYHNSObject_t{
    CFTypeRef object;
    const char *name;
    QYHNSObjectType type;
}QYHNSObject_t,*QYHNSObject,*QYHNSBlock;

typedef struct QYHNodeEnumerator_t{
    QYHNSObject object;
    const void **references;
    int size;
    unsigned currentIndex;
}*QYHNodeEnumerator;
/**
 We are mimicing Block structure based on Clang documentation:
 http://clang.llvm.org/docs/Block-ABI-Apple.html
 */

enum { // Flags from BlockLiteral
  BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
  BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
  BLOCK_IS_GLOBAL =         (1 << 28),
  BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
  BLOCK_HAS_SIGNATURE =     (1 << 30),
};

struct QYHBlockDescriptor {
  unsigned long int reserved;                // NULL
  unsigned long int size;
  // optional helper functions
  void (*copy_helper)(void *dst, void *src); // IFF (1<<25)
  void (*dispose_helper)(void *src);         // IFF (1<<25)
  const char *signature;                     // IFF (1<<30)
};

struct __attribute__((packed)) QYHBlockLiteral {
  void *isa;  // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
  int flags;
  int reserved;
  void (*invoke)(void *, ...);
  struct QYHBlockDescriptor *descriptor;
  // imported variables
};

#endif /* QYHRetainCycle_h */
