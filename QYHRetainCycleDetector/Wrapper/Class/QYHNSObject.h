//
//  QYHNSObject.h
//   
//
//  Created by qinyihui on 2020/2/2.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "QYHRetainCycle.h"

/**
 * create QYHNSObject
 * @param obj A CFTypeRef representing NSObject
 * @param ivarName A CString describing the name of an instance variable.
 */
QYHNSObject QYHNSObjectCreate(CFTypeRef obj,const char *ivarName,QYHNSObjectType type);

/**
* create QYHNSObject
* @param obj A CFTypeRef representing NSObject
* @param ivarName A CString describing the name of an instance variable.
*/
QYHNSObject QYHNSObjectCreate(CFTypeRef obj,const char *ivarName);
/**
 * free QYHNSObject
 */
void QYHNSObjectFree(QYHNSObject obj);

void QYHNSObjectTrueFree(QYHNSObject obj);

/**
 * @return An array contains all strong reference member variables the given object has
*/
CFMutableSetRef QYHGetStrongReferenceMemberVars(id obj);

/**
 @return An array contains all strong reference objects the given timer has
 */
CFMutableSetRef QYHGetNSTimerStrongReferences(id obj);

/**
 @return An CFStringRef describing the object
 */
CFStringRef QYHNSObjectDescription(QYHNSObject obj);

#pragma mark - CF collection call backs
/**
 equal call back for CFSetRef that contains object of type QYHNSObjects
 */
Boolean QYHNSObjectSetEqualCallBack(const void *value1, const void *value2);

/**
hash call back for CFSetRef that contains object of type QYHNSObjects
*/
CFHashCode QYHNSObjectSetHashCallBack(const void *value);

void QYHNSObjectClearCache();

