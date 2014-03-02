//
//  CBAsyncTestCase.h
//
//  Created by Christopher Bess
//

#import <XCTest/XCTest.h>

@interface CBAsyncTestCase : XCTestCase

/**
 * Begins the async operation watch.
 * @discussion Call before async operation begins.
 */
- (void)beginAsyncOperation;

/**
 * Finishes the async operation watch, call to complete operation and prevent timeout.
 */
- (void)finishedAsyncOperation;

/**
 * Waits for the async operation to finish or returns as a timeout.
 * @return YES if the async operation timeout interval is exceeded, NO if the
 * async operation finished.
 */
- (BOOL)waitForAsyncOperationOrTimeoutWithInterval:(NSTimeInterval)interval;
- (BOOL)waitForAsyncOperationOrTimeoutWithDefaultInterval; // timeout: 10secs

- (void)assertAsyncOperationTimeout; // uses default interval

@end
