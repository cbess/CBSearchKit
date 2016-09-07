CBSearchKit
===========

Simple and flexible full text search for iOS and Mac. Using the sqlite3 FTS3/4 engine.

## Setup

- Link `libsqlite3.dylib`
- Add `pod 'CBSearchKit'` to `Podfile`
- Run `pod update`

## Example Usage
```objc
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
    
    __typeof__(self) __weak weakSelf = self;
    [self beginAsyncOperation];
    [self.indexer addItems:documents completionHandler:^(NSArray *indexItems, NSError *error) {
        [weakSelf finishedAsyncOperation];
    }];
    
    [self waitForAsyncOperationOrTimeoutWithInterval:3];
    
    return documents;
}

- (void)testSearch {
    NSArray *indexedDocuments = [self buildIndex];
    
    XCTAssertEqual([self.indexer indexCount], indexedDocuments.count, @"Bad count");
    
    id<CBSIndexItem> oneDoc = indexedDocuments.firstObject;
    NSString * const searchText = @"*one*";
    
    [self beginAsyncOperation];
    
    CBSSearcher *searcher = [[CBSSearcher alloc] initWithIndexer:self.indexer];
    [searcher itemsWithText:searchText itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *items, NSError *error) {
        XCTAssertEqual(items.count, 1, @"Should be only one item");
        XCTAssertNil(error, @"Error: %@", error);
        
        id<CBSIndexItem> item = items.lastObject;
        NSDictionary *meta = [item indexMeta];
        
        XCTAssertNotNil(meta, @"No meta");
        XCTAssertEqualObjects(meta[@"idx"], [oneDoc indexMeta][@"idx"], @"Wrong meta value");
        XCTAssertEqualObjects([item indexItemIdentifier], [oneDoc indexItemIdentifier], @"Wrong index identifier");
        
        [self finishedAsyncOperation];
    }];
    
    [self assertAsyncOperationTimeout];
}
```

See unit tests for more examples.