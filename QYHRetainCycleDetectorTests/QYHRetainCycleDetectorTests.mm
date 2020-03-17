//
//  QYHRetainCycleDetectorTests.m
//  QYHRetainCycleDetectorTests
//
//  Created by qinyihui on 2020/3/17.
//  Copyright © 2020 qinyihui. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <QYHRetainCycleDetector/QYHRetainCycleDetector.h>
#import <QYHRetainCycleDetector/QYHRetainCycleFinder.h>

typedef void (^_RCDTestBlockType)(void);

typedef struct {
  id<NSObject> model;
  __weak id<NSObject> weakModel;
} _RCDTestStruct;

@interface _RCDTestClass : NSObject
@property (nonatomic, strong) NSObject *object;
@property (nonatomic, strong) NSObject *secondObject;
@property (nonatomic, copy) NSArray *array;
@property (nonatomic, weak) NSObject *weakObject;
@property (nonatomic, strong) _RCDTestBlockType block;
@property (nonatomic, assign) _RCDTestStruct someStruct;
@end
@implementation _RCDTestClass
@end

@interface QYHRetainCycleDetectorTests : XCTestCase

@end

@implementation QYHRetainCycleDetectorTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testThatDetectorWillFindNoCyclesInEmptyObject{
    _RCDTestClass *testObject = [_RCDTestClass new];
    bool foundRC = [QYHRetainCycleFinder detectRetainCyclesInObject:(id)testObject];
    XCTAssertTrue(!foundRC);
}

- (void)testThatDetectorWillFindCycleCreatedByOneObjectWithItself{
    _RCDTestClass *testObject = [_RCDTestClass new];
    testObject.object = testObject;
    bool foundRC = [QYHRetainCycleFinder detectRetainCyclesInObject:(id)testObject];
    XCTAssertTrue(foundRC);
}

- (void)testThatDetectorWillFindCycleCreatedByOneObjectRetainAnBlockW{
    _RCDTestClass *testObject = [_RCDTestClass new];
    __block NSObject *unretainedObject;
    _RCDTestBlockType block = ^{
        unretainedObject = testObject;
    };
    testObject.block = block;
    bool foundRC = [QYHRetainCycleFinder detectRetainCyclesInObject:(id)testObject];
    XCTAssertTrue(foundRC);
}

//- (void)testThatDetectorWillFindCycleIfPartOfItIsElementOfStruct{
//    _RCDTestClass *testObject1 = [_RCDTestClass new];
//    _RCDTestClass *testObject2 = [_RCDTestClass new];
//    
//    testObject1.someStruct = _RCDTestStruct {
//      .model = testObject2
//    };
//    
//    testObject2.object = testObject1;
//    
//    bool foundRC = [QYHRetainCycleFinder detectRetainCyclesInObject:(id)testObject1];
//    XCTAssertTrue(!foundRC);
//}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
