//
//  CBSIndexerTests.m
//  CBSearchKit
//
//  Created by C. Bess on 3/2/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBAsyncTestCase.h"
#import "CBSSearchKit.h"

@interface CBSIndexerTests : CBAsyncTestCase

@end

@implementation CBSIndexerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testCreateIndex
{
    // create in-mem index
    CBSIndexer *indexer = [[CBSIndexer alloc] initWithDatabaseNamed:@""];
    
    NSString *text = @"some text";
    [self beginAsyncOperation];
    [indexer addTextContents:text itemType:CBSIndexItemTypeIgnore completionHandler:^(NSArray *indexItems, NSError *error) {
        [self finishedAsyncOperation];
    }];
    
    [self assertAsyncOperationTimeout];
    
    XCTAssertTrue([indexer indexCount] == 1, @"wrong count");
}

@end
