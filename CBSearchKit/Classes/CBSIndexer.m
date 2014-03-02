//
//  CBSIndexer.m
//  CBSearchKit
//
//  Created by C. Bess on 2/23/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBSIndexer.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMResultSet.h>

NSString * const kCBSDefaultIndexName = @"cbs_fts";
NSString * const kCBSFTSEngineVersion3 = @"fts3";
NSString * const kCBSFTSEngineVersion4 = @"fts4";

static NSString * gFTSEngineVersion = nil;

@interface CBSIndexer () {
    dispatch_queue_t _indexQueue;
}

@property (nonatomic, copy) NSString *databasePath;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, copy) NSString *indexName;

@end

@implementation CBSIndexer

+ (void)setFTSEngineVersion:(NSString *)version {
    gFTSEngineVersion = version;
}

+ (void)initialize {
    gFTSEngineVersion = kCBSFTSEngineVersion3;
}

- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath {
    return [self initWithDatabaseAtPath:dbPath indexName:kCBSDefaultIndexName];
}

- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath indexName:(NSString *)indexName {
    self = [self init];
    if (self) {
        _databasePath = [dbPath copy];
        _indexName = [indexName copy];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _indexQueue = dispatch_queue_create("com.cbess.cbsindexer", 0);
    }
    return self;
}

- (void)createDatabaseQueueIfNeeded {
    NSAssert(self.indexName, @"No index name.");
    NSAssert(self.databasePath, @"No database path.");
    
    // no queue or the db path is different
    if (self.databaseQueue == nil || ![self.databasePath isEqualToString:self.databaseQueue.path]) {
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
    }
}

#pragma mark - Indexing

- (void)addItem:(id<CBSIndexItem>)item completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    [self addItems:@[item] completionHandler:completionHandler];
}

- (void)addItems:(NSArray *)items completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(_indexQueue, ^{
        NSMutableArray *indexedItems = [NSMutableArray array];
        
        for (id<CBSIndexItem> item in items) {
            if ([item canIndex]) {
                // store index
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler)
                completionHandler(indexedItems, nil);
        });
    });
}

- (id<CBSIndexItem>)addTextContents:(NSString *)contents completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    CBSIndexDocument *doc = [CBSIndexDocument new];
    doc.indexTextContents = contents;
    //doc.indexMeta = meta;
    
    [self addItem:doc completionHandler:^(NSArray *indexItems, NSError *error) {
        // code
    }];
    
    return doc;
}

- (void)removeItem:(id<CBSIndexItem>)item {
    
}

- (void)removeItems:(NSArray *)items {
    
}

- (void)removeItemWithID:(CBSIndexItemIdentifier)identifier {
    
}

- (void)reindexWithItems:(NSArray *)items completionHandler:(CBSIndexerReindexCompletionHandler)completionHandler {
    NSParameterAssert(items);
    
    [self createDatabaseQueueIfNeeded];
    
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(_indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdateWithFormat:@"CREATE VIRTUAL TABLE %@ USING %@ (item_id, contents)",
             weakSelf.indexName,
             gFTSEngineVersion];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(0, nil);
            }
        });
    });
}

- (void)reindexWithCompletionHandler:(CBSIndexerReindexCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(_indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            // rebuild index structure
            [db executeUpdateWithFormat:@"INSERT INTO %@(%@) VALUES ('rebuild')",
             weakSelf.indexName,
             weakSelf.indexName];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(0, nil);
            }
        });
    });
}

- (void)optimizeIndexWithCompletionHandler:(dispatch_block_t)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(_indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            // optimize the internal structure of FTS table
            [db executeUpdateWithFormat:@"INSERT INTO %s(%s) VALUES ('optimize')",
             [weakSelf.indexName UTF8String],
             [weakSelf.indexName UTF8String]];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}

@end
