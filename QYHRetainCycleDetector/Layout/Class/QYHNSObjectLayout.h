//
//  QYHNSObjectLayout.h
//  RetainCycleDetector
//
//  Created by qinyihui on 2020/2/29.
//  Copyright © 2020 qinyihui. All rights reserved.
//


#import <CoreFoundation/CoreFoundation.h>
#import "QYHRetainCycle.h"

/**
@return An array of objects of type QYHIvar representing strong reference of Ivar  declared by the class.
*/

CFArrayRef QYHGetStrongReferencesForClass(Class cls);

void QYHClearStrongReferenceIvarsCache();
