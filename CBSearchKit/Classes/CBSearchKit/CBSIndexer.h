//
//  CBSIndexer.h
//  CBSearchKit
//
//  Created by C. Bess on 2/23/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBSIndexDocument.h"

extern NSString * _Nonnull const kCBSDefaultIndexName;
extern NSString * _Nonnull const kCBSFTSEngineVersion3; // fts3
extern NSString * _Nonnull const kCBSFTSEngineVersion4; // fts4
extern NSString * _Nonnull const kCBSFTSEngineVersion5; // fts5

typedef void(^CBSIndexerReindexCompletionHandler)(NSUInteger itemCount, NSError * _Nullable error);
typedef void(^CBSIndexerItemsCompletionHandler)(NSArray<id<CBSIndexItem>> * _Nonnull indexItems, NSError * _Nullable error);
typedef void(^CBSIndexerCompletionHandler)(NSError * _Nullable error);

@class FMDatabaseQueue;

@interface CBSIndexer : NSObject

/// The GCD queue used for asynchronous index operations.
@property (nonatomic, nonnull, strong) dispatch_queue_t indexQueue;

/// Indicates if the index supports ORDER BY relevance. Rank function was successfully setup.
@property (readonly) BOOL supportsRanking;

/**
 Set the internal FTS engine used.
 
 @param version Use kCBSFTSEngineVersion* constant.
 @discussion Defaults to kCBSFTSEngineVersion4.
 */
+ (void)setFTSEngineVersion:(nonnull NSString *)version;

/**
 The path to the index database by appending the specified path component (usually the file name).
 
 @param pathComponent The path component to append. If nil or empty, then an empty path will be returned.
 @discussion The path will be in the caches directory.
 */
+ (nonnull NSString *)stringWithDatabasePathWithPathComponent:(nullable NSString *)pathComponent;

/// Returns an in-memory indexer.
+ (nonnull instancetype)indexer;

#pragma mark - Init

/**
 Initializes the receiver using the specified database name.
 
 @param dbName The name of the database to be opened or created in the cache directory. If empty, then an in-memory
 database is used.
 */
- (nonnull instancetype)initWithDatabaseNamed:(nullable NSString *)dbName;

/**
 Initializes the receiver using the specified database name.
 
 @param dbName The name of the database file to be opened or created in the cache directory. If nil or empty, then an in-memory
 database is used.
 @param indexName The name of the index within the database. If nil or empty, then the default index name is used (kCBSDefaultIndexName).
 */
- (nonnull instancetype)initWithDatabaseNamed:(nullable NSString *)dbName indexName:(nullable NSString *)indexName;

/**
 Initializes the receiver using the specified database path.
 
 @param dbName The path of the database to be opened.
 @param indexName The name of the index within the database. If nil or empty, then the default index name is used (kCBSDefaultIndexName).
 */
- (nonnull instancetype)initWithDatabaseAtPath:(nullable NSString *)dbPath indexName:(nullable NSString *)indexName;

#pragma mark - Indexing

/// Adds the specified CBSIndexItem to the receiver index.
/// @param item The CBSIndexItem object to add to the index.
/// @param completionHandler Runs in `indexQueue`.
- (void)addItem:(nonnull id<CBSIndexItem>)item completionHandler:(nullable CBSIndexerItemsCompletionHandler)completionHandler;

/// Adds the given CBSIndexItem objects to the receiver index.
/// @param items The fast enumeration collection that contains the CBSIndexItem objects.
/// @param completionHandler Runs in `indexQueue`.
- (void)addItems:(nonnull id<NSFastEnumeration>)items completionHandler:(nullable CBSIndexerItemsCompletionHandler)completionHandler;

/// Updates the index entry for the specified item.
/// @param completionHandler Runs in `indexQueue`.
/// @discussion Removes, then adds the item to the index.
- (void)updateItem:(nonnull id<CBSIndexItem>)item completionHandler:(nullable CBSIndexerItemsCompletionHandler)completionHandler;

/// Removes the item with the specified identifier from the index. Non-blocking operation.
- (void)removeItemWithID:(nonnull CBSIndexItemIdentifier)identifier;

/// Removes the item from the index.
/// @discussion The item must have a valid identifier. Non-blocking operation.
- (void)removeItem:(nonnull id<CBSIndexItem>)item;

/// Removes the given CBSIndexItem objects from the receiver index.
/// @param completionHandler Runs in `indexQueue`.
/// @discussion Each item must have a valid identifier.
- (void)removeItems:(nonnull id<NSFastEnumeration>)items completionHandler:(nullable CBSIndexerCompletionHandler)completionHandler;

/// Removes the entire index.
/// @discussion Deletes the index file.
/// @return YES if the index path is removed without error.
- (BOOL)removeAllItems;

/**
 Reindexes the entire database.
 
 @param completionHandler The completion block for this operation. Runs on the main thread.
 @discussion Rebuilds the indexes. Asynchronous operation.
 */
- (void)reindexWithCompletionHandler:(nullable CBSIndexerReindexCompletionHandler)completionHandler;

/**
 Optimizes the index database.
 
 @param completionHandler The completion block for the operation. Runs on main thread.
 @discussion Asynchronous operation.
 @see http://www.sqlite.org/fts3.html#*fts4optcmd
 */
- (void)optimizeIndexWithCompletionHandler:(nullable CBSIndexerCompletionHandler)completionHandler;

// no docs, yet
- (nonnull id<CBSIndexItem>)addTextContents:(nonnull NSString *)contents itemType:(CBSIndexItemType)itemType meta:(nullable NSDictionary *)meta completionHandler:(nullable CBSIndexerItemsCompletionHandler)completionHandler;
- (nonnull id<CBSIndexItem>)addTextContents:(nonnull NSString *)contents itemType:(CBSIndexItemType)itemType completionHandler:(nullable CBSIndexerItemsCompletionHandler)completionHandler;
- (nonnull id<CBSIndexItem>)addTextContents:(nonnull NSString *)contents completionHandler:(nullable CBSIndexerItemsCompletionHandler)completionHandler;

#pragma mark - Misc

/**
 The path to the index database.
 */
- (nonnull NSString *)databasePath;

/**
 The name of the index in the database.
 
 @discussion This is the table name.
 */
- (nonnull NSString *)indexName;

/**
 The total number of items in the database.
 
 @discussion Performs a COUNT query.
 */
- (NSUInteger)itemCount;

/**
 Used mostly for unit test or custom/special queries.
 
 @discussion The db queue used internally for prebuilt queries.
 */
- (nonnull FMDatabaseQueue *)databaseQueue;

@end
