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
#import "CBSCustomIndexDocument.h"

@interface CBSSearcherTests : XCTestCase

@property (nonatomic, strong) CBSIndexer *indexer;

@end

@implementation CBSSearcherTests

- (NSArray *)buildIndex {
    // create in-memory index
    self.indexer = [CBSIndexer indexer];
    
    CBSIndexDocument *document = [CBSIndexDocument newWithID:@"one-id"];
    document.indexTextContents = @"this is one";
    document.indexMeta = @{@"idx": @1, @"name": @"one"};
    
    CBSIndexDocument *document2 = [CBSIndexDocument newWithID:@"two-id"];
    document2.indexTextContents = @"this is two";
    document2.indexMeta = @{@"idx": @2, @"name": @"two"};
    
    CBSIndexDocument *document3 = [CBSIndexDocument newWithID:@"three-id"];
    document3.indexTextContents = @"this is three";
    document3.indexMeta = @{@"idx": @3, @"test": @"three", @"name": @"three"};
    
    NSArray *documents = @[document, document2, document3];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"build index"];
    [self.indexer addItems:documents completionHandler:^(NSArray *indexItems, NSError *error) {
        XCTAssertNil(error, @"unable to build the index");
        XCTAssertEqual(indexItems.count, documents.count, @"wrong count indexed");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    return documents;
}

- (void)testSearch {
    NSArray *indexedDocuments = [self buildIndex];
    
    XCTAssertEqual([self.indexer itemCount], indexedDocuments.count, @"Bad count");
    
    id<CBSIndexItem> oneDoc = indexedDocuments.firstObject;
    static NSString * const searchText = @"one";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"search index"];
    
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

- (void)testUpdateItem {
    [self buildIndex];
    
    CBSIndexDocument *document = [CBSIndexDocument newWithID:@"one"];
    document.indexTextContents = @"uno Dios"; // one God
    
    CBSIndexDocument *document2 = [CBSIndexDocument newWithID:@"two"];
    document2.indexTextContents = @"一王人"; // one King
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"index"];
    [self.indexer addItems:@[document, document2] completionHandler:^(NSArray<id<CBSIndexItem>> * _Nonnull indexItems, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqual(indexItems.count, 2, @"did not index items");
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    // search for initial items
    expectation = [self expectationWithDescription:@"search originals"];
    CBSSearcher *searcher = [[CBSSearcher alloc] initWithIndexer:self.indexer];
    [searcher itemsWithText:@"uno" itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *items, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(items.count, 1, @"found no items");
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    // update item
    expectation = [self expectationWithDescription:@"update"];
    document.indexTextContents = @"soli Deo gloria";
    [self.indexer updateItem:document completionHandler:^(NSArray<id<CBSIndexItem>> * _Nonnull indexItems, NSError * _Nullable error) {
        XCTAssertEqual(indexItems.count, 1, @"did not update the one item");
        XCTAssertNil(error);
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    // search for the updated items
    expectation = [self expectationWithDescription:@"search for removed"];
    searcher = [[CBSSearcher alloc] initWithIndexer:self.indexer];
    [searcher itemsWithText:@"uno" itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *items, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(items.count, 0, @"should find no items");
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    // search for the updated item
    expectation = [self expectationWithDescription:@"search again"];
    [searcher itemsWithText:@"gloria" itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *items, NSError *error) {
        id<CBSIndexItem> item = items.firstObject;
        
        XCTAssertEqual(items.count, 1, @"no items found");
        XCTAssertNil(error);
        XCTAssertEqualObjects(item.indexTextContents, @"soli Deo gloria");
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testSearchWithCustomIndexItem {
    NSArray *indexedDocuments = [self buildIndex];
    
    XCTAssertEqual([self.indexer itemCount], indexedDocuments.count, @"Bad count");
    
    id<CBSIndexItem> oneDoc = indexedDocuments.firstObject;
    static NSString * const searchText = @"one*";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"search custom index"];
    
    CBSSearcher *searcher = [[CBSSearcher alloc] initWithIndexer:self.indexer];
    
    // set the item factory to create the custom object
    [searcher setItemFactoryHandler:^id _Nonnull(id<CBSIndexItem>  _Nonnull item) {
        CBSCustomIndexDocument *object = [CBSCustomIndexDocument newWithID:item.indexItemIdentifier];
        object.uid = item.indexItemIdentifier;
        object.name = item.indexMeta[@"name"];
        object.index = item.indexMeta[@"idx"];
        
        return object;
    }];
    
    [searcher itemsWithText:searchText itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *items, NSError *error) {
        XCTAssertEqual(items.count, 1, @"Should be only one item");
        XCTAssertNil(error, @"Error: %@", error);
        
        CBSCustomIndexDocument *item = items.lastObject;
        
        // test custom object values
        XCTAssertNotNil(item, @"No meta");
        XCTAssertTrue([item isKindOfClass:[CBSCustomIndexDocument class]], @"wrong object");
        XCTAssertEqualObjects(item.index, [oneDoc indexMeta][@"idx"], @"Wrong meta value");
        XCTAssertEqualObjects(item.uid, oneDoc.indexItemIdentifier, @"Wrong index identifier");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:7 handler:nil];
}

- (void)testSearchLimit {
    NSArray *docs = [self buildIndex];
    
    XCTAssertTrue(docs.count > 2, @"not enough documents indexed");
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"search index"];
    CBSSearcher *searcher = [[CBSSearcher alloc] initWithIndexer:self.indexer];
    [searcher itemsWithText:@"is" itemType:CBSIndexItemTypeIgnore offset:0 limit:2 completionHandler:^(NSArray<id<CBSIndexItem>> * _Nonnull items, NSError * _Nullable error) {
        XCTAssertNil(error, @"error occurred: %@", error);
        XCTAssertEqual(items.count, 2, @"wrong result count");
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testSearchPriority {
    [self buildIndex];
    
    // Add items with same content but different priority
    CBSIndexDocument *doc1 = [CBSIndexDocument newWithID:@"p1" text:@"priority test"];
    doc1.priority = 10;

    CBSIndexDocument *doc2 = [CBSIndexDocument newWithID:@"p2" text:@"priority test"];
    doc2.priority = 0; // Should come first if ASC

    CBSIndexDocument *doc3 = [CBSIndexDocument newWithID:@"p3" text:@"priority test"];
    doc3.priority = 20;

    NSArray *docs = @[doc1, doc2, doc3];
    XCTestExpectation *expectation = [self expectationWithDescription:@"index priority items"];
    [self.indexer addItems:docs completionHandler:^(NSArray *indexItems, NSError *error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Search
    CBSSearcher *searcher = [[CBSSearcher alloc] initWithIndexer:self.indexer];
    
    // Rank logic:
    // All 3 items match "priority" exactly once in short string.
    // Rank should be similar.
    // So priority should determine order.
    
    XCTestExpectation *searchExpectation = [self expectationWithDescription:@"search priority"];
    
    [searcher itemsWithText:@"priority" completionHandler:^(NSArray *results, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(results.count, 3);
        
        // Check order
        CBSIndexDocument *r1 = results[0];
        CBSIndexDocument *r2 = results[1];
        CBSIndexDocument *r3 = results[2];
        
        // Expect: 0, 10, 20 (ASC)
        XCTAssertEqualObjects(r1.indexItemIdentifier, @"p2");
        XCTAssertEqualObjects(r2.indexItemIdentifier, @"p1");
        XCTAssertEqualObjects(r3.indexItemIdentifier, @"p3");
        
        [searchExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
