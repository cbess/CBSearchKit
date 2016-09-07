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
#import "CBSMacros.h"

NSString * const kCBSDefaultIndexName = @"cbs_fts";
NSString * const kCBSFTSEngineVersion3 = @"fts3";
NSString * const kCBSFTSEngineVersion4 = @"fts4";

static NSString * gFTSEngineVersion = nil;

@interface CBSIndexer () {
    dispatch_queue_t _indexQueue;
    BOOL _databaseCreated;
}

@property (nonatomic, copy) NSString *databasePath;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, copy) NSString *indexName;

@end

@implementation CBSIndexer

+ (void)initialize {
    gFTSEngineVersion = kCBSFTSEngineVersion3;
}

+ (void)setFTSEngineVersion:(NSString *)version {
    gFTSEngineVersion = version;
}

+ (NSString *)stringWithDatabasePathWithPathComponent:(NSString *)pathComp {
    if (!pathComp.length)
        return [NSString string];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:pathComp];
}

#pragma mark - Init

- (instancetype)initWithDatabaseNamed:(NSString *)dbName {
    return [self initWithDatabaseNamed:dbName indexName:nil];
}

- (instancetype)initWithDatabaseNamed:(NSString *)dbName indexName:(NSString *)indexName {
    NSString *dbPath = @":memory:";
    if (dbName.length) {
        dbPath = [[self class] stringWithDatabasePathWithPathComponent:dbName];
    }
    
    return [self initWithDatabaseAtPath:dbPath indexName:indexName];
}

- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath indexName:(NSString *)indexName {
    self = [self init];
    if (self) {
        _databasePath = [dbPath copy];
        _indexName = [indexName copy];
        
        if (!_databasePath.length) {
            _databasePath = @":memory:";
        }
        
        if (!_indexName.length) {
            _indexName = kCBSDefaultIndexName;
        }
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

#pragma mark - Misc

- (void)createDatabaseQueueIfNeeded {
    NSAssert(self.indexName, @"No index name.");
    NSAssert(self.databasePath, @"No database path.");
    
    // no queue or the db path is different
    if (self.databaseQueue == nil || ![self.databasePath isEqualToString:self.databaseQueue.path]) {
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
    }
}

- (void)createFTSIfNeeded {
    if (_databaseCreated)
        return;
    
    __typeof__(self) __weak weakSelf = self;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString *query = [NSString stringWithFormat:@"CREATE VIRTUAL TABLE %@ USING %@ (item_id, contents, item_type, item_meta)",
                           weakSelf.indexName,
                           gFTSEngineVersion];
        BOOL success = [db executeUpdate:query];
        
        if ([db hadError]) {
            CBSError([db lastError]);
        }
        
        _databaseCreated = success;
    }];
}

#pragma mark - Indexing

- (void)addItem:(id<CBSIndexItem>)item completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    [self addItems:@[item] completionHandler:completionHandler];
}

- (void)addItems:(NSArray *)items completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    [self createFTSIfNeeded];
    
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(_indexQueue, ^{
        NSMutableArray *indexedItems = [NSMutableArray array];
        __block NSError *error = nil;
        
        [weakSelf.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:5];

            // try to index all documents
            for (id<CBSIndexItem> item in items) {
                // check self, if released, bail
                if (!weakSelf) {
                    *rollback = YES;
                    return;
                }
                
                if (![item canIndex]) {
                    return;
                }
                
                @autoreleasepool {
                    NSMutableArray *queryColumns = [NSMutableArray array];
                    NSMutableArray *queryParamNames = [NSMutableArray array];
                    
                    // determine desired query to insert the data
                    
                    // contents
                    [queryColumns addObject:@"contents"];
                    [queryParamNames addObject:@":contents"];
                    params[@"contents"] = [item indexTextContents];
                    
                    // item type
                    [queryColumns addObject:@"item_type"];
                    [queryParamNames addObject:@":type"];
                    params[@"type"] = @([item indexItemType]);
                    
                    // identifier
                    NSString *identifer = [item indexItemIdentifier];
                    if (identifer.length) {
                        [queryColumns addObject:@"item_id"];
                        [queryParamNames addObject:@":identifier"];
                        params[@"identifier"] = identifer;
                    }
                    
                    // meta
                    if ([item indexMeta].count) {
                        [queryColumns addObject:@"item_meta"];
                        [queryParamNames addObject:@":meta"];
                        params[@"meta"] = [NSJSONSerialization dataWithJSONObject:[item indexMeta]
                                                                          options:0
                                                                            error:&error];
                        if (error) {
                            CBSError(error);
                            *rollback = YES;
                            break;
                        }
                    }
                    
                    // build query, store index
                    NSString *query = [NSString stringWithFormat:
                                       @"INSERT INTO %@ (%@) VALUES (%@)",
                                       weakSelf.indexName,
                                       [queryColumns componentsJoinedByString:@","],
                                       [queryParamNames componentsJoinedByString:@","]];
                    [db executeUpdate:query withParameterDictionary:params];
                    [params removeAllObjects];
                    
                    if ([db hadError]) {
                        error = [db lastError];
                        CBSError(error);
                        
                        *rollback = YES;
                        break;
                    }
                    
                    [indexedItems addObject:item];
                }
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(indexedItems, error);
            }
        });
    });
}

- (id<CBSIndexItem>)addTextContents:(NSString *)contents itemType:(CBSIndexItemType)itemType meta:(NSDictionary *)meta completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    CBSIndexDocument *doc = [CBSIndexDocument new];
    doc.indexTextContents = contents;
    doc.indexItemType = itemType;
    doc.indexMeta = meta;
    
    [self addItem:doc completionHandler:completionHandler];
    
    return doc;
}

- (id<CBSIndexItem>)addTextContents:(NSString *)contents itemType:(CBSIndexItemType)itemType completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    return [self addTextContents:contents itemType:itemType meta:nil completionHandler:completionHandler];
}

- (id<CBSIndexItem>)addTextContents:(NSString *)contents completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    return [self addTextContents:contents itemType:CBSIndexItemTypeIgnore completionHandler:completionHandler];
}

- (void)removeItem:(id<CBSIndexItem>)item {
    [self removeItems:@[item] completionHandler:nil];
}

- (void)removeItems:(NSArray *)items completionHandler:(dispatch_block_t)completionHandler {
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(_indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            for (id<CBSIndexItem> item in items) {
                NSAssert([item indexItemIdentifier], @"Unable to remove item. No item identifier.");
                
                [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE item_id = %@",
                 weakSelf.indexName,
                 [item indexItemIdentifier]]];
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}

- (void)removeItemWithID:(CBSIndexItemIdentifier)identifier {
    [self createDatabaseQueueIfNeeded];
    
    // create a temp obj
    CBSIndexDocument *item = [CBSIndexDocument new];
    item.indexItemIdentifier = identifier;
    
    [self removeItem:item];
}

- (void)reindexWithCompletionHandler:(CBSIndexerReindexCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __block NSUInteger itemCount = 0;
    __block NSError *error = nil;
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(_indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            // rebuild index structure
            [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES ('rebuild')",
             weakSelf.indexName,
             weakSelf.indexName]];
            
            if ([db hadError]) {
                error = [db lastError];
                CBSError(error);
            }
        }];
        
        itemCount = [weakSelf indexCount];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(itemCount, error);
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
            [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES ('optimize')",
             weakSelf.indexName,
             weakSelf.indexName]];
            
            if ([db hadError]) {
                CBSError([db lastError]);
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}

- (NSUInteger)indexCount {
    __block NSUInteger count = 0;
    [self createDatabaseQueueIfNeeded];
    
    __typeof__(self) __weak weakSelf = self;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:[@"SELECT COUNT(rowid) FROM " stringByAppendingString:weakSelf.indexName]];
        if ([result next]) {
            count = (NSUInteger) [result unsignedLongLongIntForColumnIndex:0];
        }
        [result close];
        
        if ([db hadError]) {
            CBSError([db lastError]);
        }
    }];
    
    return count;
}

@end
