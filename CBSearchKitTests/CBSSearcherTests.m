//
//  CBSSearcherTests.m
//  CBSearchKit
//
//  Created by C. Bess on 3/6/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CBSSearcher.h"
#import "CBSIndexer.h"

@interface CBSSearcherTests : XCTestCase

@property (nonatomic, strong) CBSIndexer *indexer;

@end

@implementation CBSSearcherTests

- (NSArray *)buildIndex {
    self.indexer = [[CBSIndexer alloc] initWithDatabaseNamed:nil];
    
    CBSIndexDocument *document = [CBSIndexDocument new];
    document.indexItemIdentifier = @"one-id";
    document.indexTextContents = @"this is one";
    document.indexMeta = @{@"idx": @1};
    
    CBSIndexDocument *document2 = [CBSIndexDocument new];
    document2.indexTextContents = @"this is two";
    document2.indexMeta = @{@"idx": @2};
    
    CBSIndexDocument *document3 = [CBSIndexDocument new];
    document3.indexTextContents = @"this is three";
    document3.indexMeta = @{@"idx": @3, @"test": @"three"};
    
    NSArray *documents = @[document, document2, document3];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"build index"];
    [self.indexer addItems:documents completionHandler:^(NSArray *indexItems, NSError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    return documents;
}

- (void)testSearch {
    NSArray *indexedDocuments = [self buildIndex];
    
    XCTAssertEqual([self.indexer itemCount], indexedDocuments.count, @"Bad count");
    
    id<CBSIndexItem> oneDoc = indexedDocuments.firstObject;
    NSString * const searchText = @"*one*";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"build index"];
    
    CBSSearcher *searcher = [[CBSSearcher alloc] initWithIndexer:self.indexer];
    [searcher itemsWithText:searchText itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *items, NSError *error) {
        XCTAssertEqual(items.count, 1, @"Should be only one item");
        XCTAssertNil(error, @"Error: %@", error);
        
        id<CBSIndexItem> item = items.lastObject;
        NSDictionary *meta = [item indexMeta];
        
        XCTAssertNotNil(meta, @"No meta");
        XCTAssertEqualObjects(meta[@"idx"], [oneDoc indexMeta][@"idx"], @"Wrong meta value");
        XCTAssertEqualObjects([item indexItemIdentifier], [oneDoc indexItemIdentifier], @"Wrong index identifier");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:7 handler:nil];
}

@end
