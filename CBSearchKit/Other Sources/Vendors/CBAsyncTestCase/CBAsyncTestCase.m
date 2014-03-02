//
//  CBAsyncTestCase.m
//
//  Created by Christopher Bess
//  

#import "CBAsyncTestCase.h"

@implementation CBAsyncTestCase {
    dispatch_semaphore_t _networkSemaphore;
    BOOL _didTimeout;
}

- (void)beginAsyncOperation
{
    _didTimeout = NO;
    _networkSemaphore = dispatch_semaphore_create(0);
}

- (void)finishedAsyncOperation
{
    _didTimeout = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutAsyncOperation) object:nil];
    
    dispatch_semaphore_signal(_networkSemaphore);
}

- (BOOL)waitForAsyncOperationOrTimeoutWithDefaultInterval
{
    return [self waitForAsyncOperationOrTimeoutWithInterval:10];
}

- (BOOL)waitForAsyncOperationOrTimeoutWithInterval:(NSTimeInterval)interval
{
    [self performSelector:@selector(timeoutAsyncOperation) withObject:nil afterDelay:interval];
    
    // wait for the semaphore to be signaled (triggered)
    while (dispatch_semaphore_wait(_networkSemaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
    
    return _didTimeout;
}

- (void)timeoutAsyncOperation
{
    _didTimeout = YES;
    dispatch_semaphore_signal(_networkSemaphore);
    
    // uncomment if you want the test case to fail when a timeout occurs
    //STFail(@"Async operation timed out.");
}

- (void)assertAsyncOperationTimeout
{
    XCTAssertFalse([self waitForAsyncOperationOrTimeoutWithDefaultInterval], @"timed out");
}

@end
