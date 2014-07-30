//
//  CBSSearcherTests.m
//  CBSearchKit
//
//  Created by C. Bess on 3/6/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBAsyncTestCase.h"
#import "CBSSearcher.h"
#import "CBSIndexer.h"

@interface CBSSearcherTests : CBAsyncTestCase

@property (nonatomic, strong) CBSIndexer *indexer;

@end

@implementation CBSSearcherTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)buildIndex {
    self.indexer = [[CBSIndexer alloc] initWithDatabaseNamed:nil];
    CBSIndexDocument *document = [CBSIndexDocument new];
    document.indexTextContents = @"this is one";
    document.indexMeta = @{@"idx": @1};
    CBSIndexDocument *document2 = [CBSIndexDocument new];
    document2.indexTextContents = @"this is two";
    document2.indexMeta = @{@"idx": @2};
    CBSIndexDocument *document3 = [CBSIndexDocument new];
    document3.indexTextContents = @"this is three";
    document3.indexMeta = @{@"idx": @3, @"test": @"three"};
    NSArray *documents = @[document, document2, document3];
    
    __typeof__(self) __weak weakSelf = self;
    [self beginAsyncOperation];
    [self.indexer addItems:documents completionHandler:^(NSArray *indexItems, NSError *error) {
        [weakSelf finishedAsyncOperation];
    }];
    
    [self waitForAsyncOperationOrTimeoutWithInterval:3];
}

- (void)testSearch {
    [self buildIndex];
    
    XCTAssertTrue([self.indexer indexCount] > 2, @"bad count");
    
    NSString *text = @"*one*";
    CBSSearcher *searcher = [[CBSSearcher alloc] initWithIndexer:self.indexer];
    [self beginAsyncOperation];
    [searcher itemsWithText:text itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *items, NSError *error) {
        XCTAssertEqual(items.count, 1, @"should be only one item");
        XCTAssertNil(error, @"error: %@", error);
        XCTAssertNotNil([items.lastObject indexMeta], @"No meta");
        
        [self finishedAsyncOperation];
    }];
    
    [self assertAsyncOperationTimeout];
}

@end
