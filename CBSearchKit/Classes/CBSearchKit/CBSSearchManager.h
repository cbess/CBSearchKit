//
//  CBSSearchManager.h
//  CBSearchKit
//
//  Created by C. Bess on 2/24/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBSIndexer.h"

/// Not used, yet
@interface CBSSearchManager : NSObject

@property (nonatomic, readonly) CBSIndexer *searchIndexer;

+ (instancetype)searchManagerWithDatabaseAtPath:(NSString *)dbPath;

@end
