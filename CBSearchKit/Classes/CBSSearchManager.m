//
//  CBSSearchManager.m
//  CBSearchKit
//
//  Created by C. Bess on 2/24/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBSSearchManager.h"

@implementation CBSSearchManager
@synthesize searchIndexer = _searchIndexer;

+ (instancetype)searchManagerWithDatabaseAtPath:(NSString *)dbPath {
    CBSSearchManager *manager = [[self class] new];
    return manager;
}

- (CBSIndexer *)searchIndexer {
    if (_searchIndexer == nil) {
        _searchIndexer = [CBSIndexer new];
    }
    return _searchIndexer;
}

@end
