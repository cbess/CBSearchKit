//
//  CBSIndexer.h
//  CBSearchKit
//
//  Created by C. Bess on 2/23/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBSIndexDocument.h"

extern NSString * const kCBSDefaultIndexName;
extern NSString * const kCBSFTSEngineVersion3; // fts3
extern NSString * const kCBSFTSEngineVersion4; // fts4

typedef void(^CBSIndexerReindexCompletionHandler)(NSUInteger docCount, NSError *error);
typedef void(^CBSIndexerItemsCompletionHandler)(NSArray *indexItems, NSError *error);


@interface CBSIndexer : NSObject

/**
 Set the internal FTS engine used.
 @param version Use kCBSFTSEngineVersion* constant.
 @discussion Defaults to kCBSFTSEngineVersion3.
 */
+ (void)setFTSEngineVersion:(NSString *)version;

- (instancetype)initWithDatabaseNamed:(NSString *)dbName;
- (instancetype)initWithDatabaseNamed:(NSString *)dbName indexName:(NSString *)indexName;
- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath indexName:(NSString *)indexName;

#pragma mark - Indexing

- (id<CBSIndexItem>)addTextContents:(NSString *)contents itemType:(CBSIndexItemType)itemType completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;
- (void)addItem:(id<CBSIndexItem>)item completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;
- (void)addItems:(NSArray *)items completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;

- (void)removeItemWithID:(CBSIndexItemIdentifier)identifier;
- (void)removeItem:(id<CBSIndexItem>)item;
- (void)removeItems:(NSArray *)items completionHandler:(dispatch_block_t)completionHandler;

/**
 Reindexes the entire database.
 
 @param completionHandler The completion block for this operation. Runs on the main thread.
 @discussion Rebuilds the indexes. Asynchronous operation.
 */
- (void)reindexWithCompletionHandler:(CBSIndexerReindexCompletionHandler)completionHandler;

/**
 Optimizes the index database.
 
 @param completionHandler The completion block for the operation. Runs on main thread.
 @discussion Asynchronous operation.
 @see http://www.sqlite.org/fts3.html#*fts4optcmd
 */
- (void)optimizeIndexWithCompletionHandler:(dispatch_block_t)completionHandler;

#pragma mark - Misc

/**
 The path to the index database.
 */
- (NSString *)databasePath;

/**
 The name of the index in the database.
 @discussion This is the table name.
 */
- (NSString *)indexName;

/**
 The total number of index items in the database.
 
 @discussion Performs a COUNT query.
 */
- (NSUInteger)indexCount;

@end
