//
//  CBSIndexDocument.m
//  CBSearchKit
//
//  Created by C. Bess on 2/27/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBSIndexDocument.h"

@implementation CBSIndexDocument

- (NSString *)indexItemIdentifierKey {
    return @"indexItemIdentifier";
}

- (BOOL)canIndex {
    return YES;
}

@end
