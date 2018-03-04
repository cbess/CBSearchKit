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

/// Returns a custom object that represents the specified item.
typedef id _Nonnull (^CBSSearcherItemFactoryHandler)(id<CBSIndexItem> _Nonnull item);

@class CBSIndexer;

@interface CBSSearcher : NSObject

/// The GCD queue used for asynchronous search operations.
@property (nonatomic, nonnull, strong) dispatch_queue_t searchQueue;

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

/**
 Sets the handler used to create item objects. It converts CBSIndexItem into custom objects.
 @discussion This is used to create objects that are given passed to the search item handlers.
 */
- (void)setItemFactoryHandler:(nullable CBSSearcherItemFactoryHandler)handler;

@end
