//
//  CBSHeader.h
//  CBSearchKit
//
//  Created by C. Bess on 3/1/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#ifndef CBSearchKit_CBSHeader_h
#define CBSearchKit_CBSHeader_h

#if defined(DEBUG) && defined(CBS_LOGS)
#   define CBSLog(PREFIX, MSG, ...) NSLog((PREFIX@" [%s:%d] "MSG), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define CBSLog(PREFIX, MSG, ...) ;
#endif

#define CBSError(ERR) if (ERR) { CBSLog(@"<Error> ", @"%@", ERR); }

#endif
