CBSearchKit
===========

Simple and flexible full text search for iOS and Mac. Using the sqlite3 FTS3/4 engine.

## Installation

### Swift Package Manager

1. In Xcode, select File > Add Packages...
2. Enter the package URL: `https://github.com/cbess/CBSearchKit.git`
3. Add the `CBSearchKit` library to your target.

Alternatively, add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/cbess/CBSearchKit.git", from: "0.7.0")
]
```

## Example Usage

```objc
- (NSArray *)buildIndex {
    // create in-memory index
    self.indexer = [[CBSIndexer alloc] initWithDatabaseNamed:nil];

    CBSIndexDocument *document = [CBSIndexDocument new];
    document.indexItemIdentifier = @"one-id";
    document.indexTextContents = @"this is one";
    document.indexMeta = @{@"idx": @1, @"name": @"one"};

    CBSIndexDocument *document2 = [CBSIndexDocument new];
    document2.indexTextContents = @"this is two";
    document2.indexMeta = @{@"idx": @2, @"name": @"two"};

    CBSIndexDocument *document3 = [CBSIndexDocument new];
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
    searcher.orderType = CBSSearcherOrderTypeRelevance;
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
```

See [unit tests](CBSearchKitTests) for more examples.

[Soli Deo Gloria](http://perfectGod.com)
