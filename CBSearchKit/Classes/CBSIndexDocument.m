//
//  CBSIndexDocument.m
//  CBSearchKit
//
//  Created by C. Bess on 2/27/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBSIndexDocument.h"

NSInteger const CBSIndexItemTypeIgnore = -1;

@implementation CBSIndexDocument

- (id)init {
    self = [super init];
    if (self) {
        _indexItemType = CBSIndexItemTypeIgnore;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    CBSIndexDocument *doc = [[self class] new];
    doc.indexItemIdentifier = nil;
    doc.indexTextContents = self.indexTextContents;
    doc.indexItemType = self.indexItemType;
    doc.indexMeta = self.indexMeta;
    
    return doc;
}

- (NSString *)indexItemIdentifierKey {
    return @"indexItemIdentifier";
}

- (BOOL)canIndex {
    return YES;
}

@end
