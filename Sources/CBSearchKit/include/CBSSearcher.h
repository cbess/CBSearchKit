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

typedef NS_ENUM(NSInteger, CBSSearcherOrderType) {
    /// Ordered naturally (default)
    CBSSearcherOrderTypeDefault,
    /// Ordered from most to least relevant
    CBSSearcherOrderTypeRelevance
};

@class CBSIndexer;

/// Represents a searcher that searches a `CBSIndexer` reference.
@interface CBSSearcher : NSObject

/// The GCD queue used for asynchronous search operations.
@property (nonatomic, nonnull, strong) dispatch_queue_t searchQueue;

/// The indexer used internally for this searcher.
@property (nonatomic, nonnull, readonly) CBSIndexer *indexer;

/// The searcher results order type. Defaults to `CBSSearcherOrderTypeDefault`.
@property (nonatomic, assign) CBSSearcherOrderType orderType;

/// Initializes the searcher with the specified indexer.
- (nonnull instancetype)initWithIndexer:(nonnull CBSIndexer *)indexer;

/// Initializes the searcher with the indexer at the specified path with the name.
- (nonnull instancetype)initWithDatabaseAtPath:(nullable NSString *)dbPath indexName:(nonnull NSString *)indexName;
- (nonnull instancetype)initWithDatabaseAtPath:(nullable NSString *)dbPath;

/// Initializes the searcher with an indexer with the specified `dbName` in cache with the indexe name.
- (nonnull instancetype)initWithDatabaseNamed:(nullable NSString *)dbName indexName:(nonnull NSString *)indexName;
- (nonnull instancetype)initWithDatabaseNamed:(nullable NSString *)dbName;

/**
 Searches the index for documents with the specified text in the contents.
 @param textContents The text to search for in the index.
 @param itemType The item type to collect in the results.
 @param offset The `offset` of the results. Must have a value of one or more to be applied.
 @param limit The `limit` for the results. Must have a value of one of more to be applied.
 */
- (void)itemsWithText:(nonnull NSString *)textContents
             itemType:(CBSIndexItemType)itemType
               offset:(NSUInteger)offset
                limit:(NSUInteger)limit
    completionHandler:(nullable CBSSearcherItemsCompletionHandler)completionHandler;
- (void)itemsWithText:(nonnull NSString *)textContents itemType:(CBSIndexItemType)itemType completionHandler:(nonnull CBSSearcherItemsCompletionHandler)completionHandler;
- (void)itemsWithText:(nonnull NSString *)textContents completionHandler:(nonnull CBSSearcherItemsCompletionHandler)completionHandler;

/// Enumerates the search results that match the specified text.
- (void)enumerateItemsWithText:(nonnull NSString *)textContents itemType:(CBSIndexItemType)itemType enumerationHandler:(nonnull CBSSearcherItemsEnumerationHandler)enumerationHandler;
- (void)enumerateItemsWithText:(nonnull NSString *)textContents enumerationHandler:(nonnull CBSSearcherItemsEnumerationHandler)enumerationHandler;

/**
 Sets the handler used to create item objects. It converts `CBSIndexItem` into custom objects.
 @discussion This is used to create objects that are passed to the search item handlers.
 */
- (void)setItemFactoryHandler:(nullable CBSSearcherItemFactoryHandler)handler;

@end
