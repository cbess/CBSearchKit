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
    self.indexer = [CBSIndexer indexer];
}

- (void)testIndexText {
    NSString *text = @"some text";
    XCTestExpectation *expectation = [self expectationWithDescription:@"index text"];
    
    [self.indexer addTextContents:text itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *indexItems, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(indexItems.count, 1, @"bad index item count");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    XCTAssertEqual([self.indexer itemCount], 1, @"wrong count");
}

- (void)testRemoveItems {
    XCTestExpectation *expectation = [self expectationWithDescription:@"index item"];
    id<CBSIndexItem> item = [self.indexer addTextContents:@"some text" completionHandler:^(NSArray *indexItems, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(1, indexItems.count, @"bad index item count");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];

    XCTAssertEqual([self.indexer itemCount], 1, @"wrong count");
    
    expectation = [self expectationWithDescription:@"remove item"];
    [self.indexer removeItems:@[item] completionHandler:^(NSError * _Nullable error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    XCTAssertEqual([self.indexer itemCount], 0, @"wrong count");
}

- (void)testOptimize {
    XCTestExpectation *expectation = [self expectationWithDescription:@"optimize"];
    
    __typeof__(self) __weak weakSelf = self;
    [self.indexer addTextContents:@"test" completionHandler:^(NSArray *indexItems, NSError *error) {
        [weakSelf.indexer optimizeIndexWithCompletionHandler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testReindex {
    XCTestExpectation *expectation = [self expectationWithDescription:@"reindex"];
    CBSIndexDocument *doc1 = [CBSIndexDocument newWithID:@"one" text:@"some text"];
    CBSIndexDocument *doc2 = [CBSIndexDocument newWithID:@"two" text:@"some text"];
    CBSIndexDocument *doc3 = [CBSIndexDocument newWithID:@"three" text:@"some text"];
    
    NSArray *documents = @[doc1, doc2, doc3];
    
    __typeof__(self) __weak weakSelf = self;
    __block NSUInteger count = 0;
    [self.indexer addItems:documents completionHandler:^(NSArray *indexItems, NSError *error) {
        XCTAssertNil(error);
        
        [weakSelf.indexer reindexWithCompletionHandler:^(NSUInteger itemCount, NSError *error) {
            XCTAssertNil(error);
            
            count = itemCount;
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    XCTAssertEqual(count, documents.count, @"bad count");
}

@end
