//
//  TestRACSubscriberTests.m
//  TestRACSubscriberTests
//
//  Created by ys on 2018/11/14.
//  Copyright © 2018 com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <ReactiveCocoa.h>

@interface TestRACSubscriberTests : XCTestCase

@end

@implementation TestRACSubscriberTests

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

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)test1
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:nil];
        [subscriber sendCompleted];
        
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"结束了");
        }];
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"test1 -- %@", x);
    }];
    
    // 打印日志
    /*
     2018-11-14 18:22:26.925204+0800 TestRACSubscriber[7055:2380811] test1 -- (null)
     2018-11-14 18:22:26.925453+0800 TestRACSubscriber[7055:2380811] 结束了
     */
}


- (void)test2
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        RACDisposable *d = [[RACScheduler mainThreadScheduler] afterDelay:0.3 schedule:^{
            
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        }];
        
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"结束了");
            [d dispose];
        }];
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"test2 -- %@", x);
    }];
    
    [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
    
    // 打印日志
    /*
     2018-11-14 18:25:56.233875+0800 TestRACSubscriber[7201:2383360] test2 -- (null)
     2018-11-14 18:25:56.234550+0800 TestRACSubscriber[7201:2383360] 结束了
     */
}

- (void)test3
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        RACDisposable *d = [[RACScheduler mainThreadScheduler] afterDelay:0.3 schedule:^{
            
            NSLog(@"test3 -- xxx");
        }];
        
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"结束了");
            [d dispose];
        }];
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"test3 -- %@", x);
    }];
    
    [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
    
    // 打印日志
    /*
     2018-11-14 18:33:02.400545+0800 TestRACSubscriber[7474:2387962] 结束了
     */
}


- (void)test4
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        RACDisposable *d = [[RACScheduler mainThreadScheduler] afterDelay:0.3 schedule:^{
            
            NSLog(@"test4 -- xxx -- %@", subscriber);
        }];
        
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"结束了");
            [d dispose];
        }];
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"test4 -- %@", x);
    }];
    
    [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
    
    // 打印日志
    /*
     2018-11-14 18:39:51.437398+0800 TestRACSubscriber[7715:2391572] test4 -- xxx -- <RACPassthroughSubscriber: 0x600000f6f7a0>
     2018-11-14 18:39:51.437689+0800 TestRACSubscriber[7715:2391572] 结束了
     */
}


@end
