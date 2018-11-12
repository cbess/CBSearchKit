//
//  CBSIndexerTests.m
//  CBSearchKit
//
//  Created by C. Bess on 3/2/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CBSearchKit.h"

@interface CBSIndexerTests : XCTestCase
@property (nonatomic, strong) CBSIndexer *indexer;
@end

@implementation CBSIndexerTests

- (void)setUp {
    [super setUp];
    
    // in-mem index database
    self.indexer = [[CBSIndexer alloc] initWithDatabaseNamed:@""];
}

- (void)testCreateIndex {
    NSString *text = @"some text";
    XCTestExpectation *expectation = [self expectationWithDescription:@"create index"];
    
    __block NSInteger count = 0;
    [self.indexer addTextContents:text itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *indexItems, NSError *error) {
        count = indexItems.count;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    XCTAssertEqual(count, 1, @"bad index item count");
    XCTAssertEqual([self.indexer itemCount], 1, @"wrong count");
}

- (void)testOptimize {
    XCTestExpectation *expectation = [self expectationWithDescription:@"optimize"];
    
    __typeof__(self) __weak weakSelf = self;
    [self.indexer addTextContents:@"test" completionHandler:^(NSArray *indexItems, NSError *error) {
        [weakSelf.indexer optimizeIndexWithCompletionHandler:^{
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testReindex {
    XCTestExpectation *expectation = [self expectationWithDescription:@"reindex"];
    CBSIndexDocument *document = [CBSIndexDocument new];
    document.indexTextContents = @"some text";
    NSArray *documents = @[document, document.copy, document.copy];
    
    __typeof__(self) __weak weakSelf = self;
    __block NSUInteger count = 0;
    [self.indexer addItems:documents completionHandler:^(NSArray *indexItems, NSError *error) {
        [weakSelf.indexer reindexWithCompletionHandler:^(NSUInteger itemCount, NSError *error) {
            count = itemCount;
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    XCTAssertEqual(count, documents.count, @"bad count");
}

@end
