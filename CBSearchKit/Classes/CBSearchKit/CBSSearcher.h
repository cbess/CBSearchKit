//
//  CBSSearcher.h
//  CBSearchKit
//
//  Created by C. Bess on 2/26/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBSIndexDocument.h"

typedef void(^CBSSearcherItemsCompletionHandler)(NSArray *items, NSError *error);
typedef void(^CBSSearcherItemsEnumerationHandler)(id<CBSIndexItem> item, BOOL *stop);

@class CBSIndexer;

@interface CBSSearcher : NSObject

- (instancetype)initWithIndexer:(CBSIndexer *)indexer;
- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath indexName:(NSString *)indexName;
- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath;
- (instancetype)initWithDatabaseNamed:(NSString *)dbName indexName:(NSString *)indexName;
- (instancetype)initWithDatabaseNamed:(NSString *)dbName;

- (CBSIndexer *)indexer;

- (void)itemsWithText:(NSString *)textContents
             itemType:(CBSIndexItemType)itemType
               offset:(NSInteger)offset // not supported, yet
                limit:(NSInteger)limit // not supported, yet
    completionHandler:(CBSSearcherItemsCompletionHandler)completionHandler;
- (void)itemsWithText:(NSString *)textContents itemType:(CBSIndexItemType)itemType completionHandler:(CBSSearcherItemsCompletionHandler)completionHandler;
- (void)itemsWithText:(NSString *)textContents completionHandler:(CBSSearcherItemsCompletionHandler)completionHandler;
- (void)enumerateItemsWithText:(NSString *)textContents itemType:(CBSIndexItemType)itemType enumerationHandler:(CBSSearcherItemsEnumerationHandler)enumerationHandler;
- (void)enumerateItemsWithText:(NSString *)textContents enumerationHandler:(CBSSearcherItemsEnumerationHandler)enumerationHandler;

@end
