//
//  CBSSearcher.h
//  CBSearchKit
//
//  Created by C. Bess on 2/26/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBSIndexDocument.h"

typedef void(^CBSSearcherItemsCompletionHandler)(NSArray<id<CBSIndexItem>> * _Nonnull items, NSError * _Nullable error);
typedef void(^CBSSearcherItemsEnumerationHandler)(id<CBSIndexItem> _Nonnull item, BOOL * _Nonnull stop);

@class CBSIndexer;

@interface CBSSearcher : NSObject

- (nonnull)initWithIndexer:(nonnull CBSIndexer *)indexer;
- (nonnull)initWithDatabaseAtPath:(nullable NSString *)dbPath indexName:(nonnull NSString *)indexName;
- (nonnull)initWithDatabaseAtPath:(nullable NSString *)dbPath;
- (nonnull)initWithDatabaseNamed:(nullable NSString *)dbName indexName:(nonnull NSString *)indexName;
- (nonnull)initWithDatabaseNamed:(nullable NSString *)dbName;

- (nonnull CBSIndexer *)indexer;

- (void)itemsWithText:(nonnull NSString *)textContents
             itemType:(CBSIndexItemType)itemType
               offset:(NSInteger)offset // not supported, yet
                limit:(NSInteger)limit // not supported, yet
    completionHandler:(nullable CBSSearcherItemsCompletionHandler)completionHandler;
- (void)itemsWithText:(nonnull NSString *)textContents itemType:(CBSIndexItemType)itemType completionHandler:(nonnull CBSSearcherItemsCompletionHandler)completionHandler;
- (void)itemsWithText:(nonnull NSString *)textContents completionHandler:(nonnull CBSSearcherItemsCompletionHandler)completionHandler;
- (void)enumerateItemsWithText:(nonnull NSString *)textContents itemType:(CBSIndexItemType)itemType enumerationHandler:(nonnull CBSSearcherItemsEnumerationHandler)enumerationHandler;
- (void)enumerateItemsWithText:(nonnull NSString *)textContents enumerationHandler:(nonnull CBSSearcherItemsEnumerationHandler)enumerationHandler;

@end
