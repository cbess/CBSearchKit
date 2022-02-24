//
//  CBSIndexer.m
//  CBSearchKit
//
//  Created by C. Bess on 2/23/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBSIndexer.h"
#import <fmdb/FMDB.h>
#import "sqlite3_rank_func.h"
#import "CBSMacros.h"

NSString * const kCBSDefaultIndexName = @"cbs_fts";
NSString * const kCBSFTSEngineVersion3 = @"fts3";
NSString * const kCBSFTSEngineVersion4 = @"fts4";
NSString * const kCBSFTSEngineVersion5 = @"fts5";

static NSString * gFTSEngineVersion = nil;

@interface CBSIndexer () {
    BOOL _supportsRanking;
}

@property (nonatomic, copy) NSString *databasePath;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, copy) NSString *indexName;
@property (nonatomic, assign) BOOL databaseCreated;

@end

@implementation CBSIndexer

+ (void)initialize {
    gFTSEngineVersion = kCBSFTSEngineVersion4;
}

+ (void)setFTSEngineVersion:(NSString *)version {
    gFTSEngineVersion = version;
}

+ (NSString *)stringWithDatabasePathWithPathComponent:(NSString *)pathComp {
    if (!pathComp.length) {
        return [NSString string];
    }
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:pathComp];
}

+ (id)indexer {
    return [[self alloc] initWithDatabaseNamed:nil];
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

- (BOOL)supportsRanking {
    return _supportsRanking;
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
    if (self.databaseCreated) {
        return;
    }
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString *query = [NSString stringWithFormat:
                           @"CREATE VIRTUAL TABLE IF NOT EXISTS %@ USING %@ (item_id, contents, item_type, item_meta)",
                           self.indexName,
                           gFTSEngineVersion];
        BOOL success = [db executeUpdate:query];
        
        if ([db hadError]) {
            CBSError([db lastError]);
        }
        
        self.databaseCreated = success;
        
        if (success) {
            // setup the rank function
            sqlite3 *sqlDb = db.sqliteHandle;
            int result = sqlite3_create_function(sqlDb, "rank", -1, SQLITE_ANY, NULL, rankfunc, NULL, NULL);
            if (result == 0) {
                self->_supportsRanking = YES;
            }
        }
    }];
}

#pragma mark - Indexing

- (void)addItem:(id<CBSIndexItem>)item completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    [self addItems:@[item] completionHandler:completionHandler];
}

- (void)addItems:(id<NSFastEnumeration>)items completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    [self createFTSIfNeeded];
    
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.indexQueue, ^{
        NSMutableArray *indexedItems = [NSMutableArray array];
        __block NSError *error = nil;
        
        [weakSelf.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:5];

            // try to index all documents
            for (id<CBSIndexItem> item in items) {
                // check self, if released, bail
                if (!weakSelf) {
                    NSError *error = [NSError errorWithDomain:@"error.cbsindexer"
                                                         code:0
                                                     userInfo:@{NSLocalizedDescriptionKey: @"indexer released"}];
                    CBSError(error);
                    
                    *rollback = YES;
                    return;
                }
                
                if (![item canIndex]) {
                    continue;
                }
                
                @autoreleasepool {
                    [item willIndex];
                    
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
                    [item didIndex];
                }
            }
        }];
        
        if (completionHandler) {
            completionHandler(indexedItems, error);
        }
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

- (void)updateItem:(id<CBSIndexItem>)item completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    __typeof__(self) __weak weakSelf = self;
    [self removeItems:@[item] completionHandler:^(NSError * _Nullable error) {
        if (error && completionHandler) {
            completionHandler(@[], error);
            return;
        }
        
        // re-add item
        [weakSelf addItem:item completionHandler:completionHandler];
    }];
}

- (void)removeItem:(id<CBSIndexItem>)item {
    [self removeItems:@[item] completionHandler:nil];
}

- (void)removeItems:(id<NSFastEnumeration>)items completionHandler:(CBSIndexerCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __block NSError *error = nil;
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            for (id<CBSIndexItem> item in items) {
                NSAssert([item indexItemIdentifier], @"Unable to remove item. No item identifier.");
                
                [db executeUpdate:[NSString stringWithFormat:
                                   @"DELETE FROM %@ WHERE item_id MATCH '%@'",
                                   weakSelf.indexName,
                                   [item indexItemIdentifier]]];
                
                if ([db hadError]) {
                    error = [db lastError];
                    CBSError(error);
                }
            }
        }];
        
        if (completionHandler) {
            completionHandler(error);
        }
    });
}

- (void)removeItemWithID:(CBSIndexItemIdentifier)identifier {
    // create a temp doc
    CBSIndexDocument *item = [CBSIndexDocument new];
    item.indexItemIdentifier = identifier;
    
    [self removeItem:item];
}

- (BOOL)removeAllItems {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.databasePath error:&error];
    
    if (!error) {
        self.databaseQueue = nil;
        self.databaseCreated = NO;
        return YES;
    } else {
        CBSError(error);
    }
    
    return NO;
}

- (void)reindexWithCompletionHandler:(CBSIndexerReindexCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __block NSUInteger itemCount = 0;
    __block NSError *error = nil;
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            // rebuild index structure
            [db executeUpdate:[NSString stringWithFormat:
                               @"INSERT INTO %@ (%@) VALUES ('rebuild')",
                               weakSelf.indexName,
                               weakSelf.indexName]];
            
            if ([db hadError]) {
                error = [db lastError];
                CBSError(error);
            }
        }];
        
        itemCount = [weakSelf itemCount];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(itemCount, error);
            }
        });
    });
}

- (void)optimizeIndexWithCompletionHandler:(CBSIndexerCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __block NSError *error = nil;
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            // optimize the internal structure of FTS table
            [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES ('optimize')",
             weakSelf.indexName,
             weakSelf.indexName]];
            
            if ([db hadError]) {
                error = [db lastError];
                CBSError(error);
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(error);
            }
        });
    });
}

- (NSUInteger)itemCount {
    __block NSUInteger count = 0;
    [self createDatabaseQueueIfNeeded];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:[@"SELECT COUNT(rowid) FROM " stringByAppendingString:self.indexName]];
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
