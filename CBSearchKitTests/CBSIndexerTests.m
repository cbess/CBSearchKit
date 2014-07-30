//
//  CBSIndexerTests.m
//  CBSearchKit
//
//  Created by C. Bess on 3/2/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBAsyncTestCase.h"
#import "CBSearchKit.h"

@interface CBSIndexerTests : CBAsyncTestCase
@property (nonatomic, strong) CBSIndexer *indexer;
@end

@implementation CBSIndexerTests

- (void)setUp
{
    [super setUp];
    
    [self beginAsyncOperation];
    // in-mem index database
    self.indexer = [[CBSIndexer alloc] initWithDatabaseNamed:@""];
}

- (void)testCreateIndex {
    NSString *text = @"some text";
    __block NSInteger count = 0;
    __typeof__(self) __weak weakSelf = self;
    [self.indexer addTextContents:text itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *indexItems, NSError *error) {
        count = indexItems.count;
        [weakSelf finishedAsyncOperation];
    }];
    
    [self assertAsyncOperationTimeout];
    
    XCTAssertEqual(count, 1, @"bad index item count");
    XCTAssertEqual([self.indexer indexCount], 1, @"wrong count");
}

- (void)testOptimize {
    __typeof__(self) __weak weakSelf = self;
    [self.indexer addTextContents:@"test" completionHandler:^(NSArray *indexItems, NSError *error) {
        [weakSelf.indexer optimizeIndexWithCompletionHandler:^{
            [weakSelf finishedAsyncOperation];
        }];
    }];
    
    [self assertAsyncOperationTimeout];
}

- (void)testReindex {
    CBSIndexDocument *document = [CBSIndexDocument new];
    document.indexTextContents = @"some text";
    NSArray *documents = @[document, document.copy, document.copy];
    
    __typeof__(self) __weak weakSelf = self;
    __block NSUInteger count = 0;
    [self.indexer addItems:documents completionHandler:^(NSArray *indexItems, NSError *error) {
        [weakSelf.indexer reindexWithCompletionHandler:^(NSUInteger itemCount, NSError *error) {
            count = itemCount;
            [weakSelf finishedAsyncOperation];
        }];
    }];
    
    [self assertAsyncOperationTimeout];
    XCTAssertEqual(count, documents.count, @"bad count");
}

@end
