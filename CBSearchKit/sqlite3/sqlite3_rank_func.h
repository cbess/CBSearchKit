/*
 *  sqlite3_rank_func.h
 */

#include "sqlite3.h"

/*
 ** SQLite user defined function to use with matchinfo() to calculate the
 ** relevancy of an FTS match. The value returned is the relevancy score
 ** (a real value greater than or equal to zero). A larger value indicates
 ** a more relevant document.
 **
 ** The overall relevancy returned is the sum of the relevancies of each
 ** column value in the FTS table. The relevancy of a column value is the
 ** sum of the following for each reportable phrase in the FTS query:
 **
 **   (<hit count> / <global hit count>) * <column weight>
 **
 ** where <hit count> is the number of instances of the phrase in the
 ** column value of the current row and <global hit count> is the number
 ** of instances of the phrase in the same column of all rows in the FTS
 ** table. The <column weight> is a weighting factor assigned to each
 ** column by the caller (see below).
 **
 ** The first argument to this function must be the return value of the FTS
 ** matchinfo() function. Following this must be one argument for each column
 ** of the FTS table containing a numeric weight factor for the corresponding
 ** column. Example:
 **
 **     CREATE VIRTUAL TABLE documents USING fts3(title, content)
 **
 ** The following query returns the docids of documents that match the full-text
 ** query <query> sorted from most to least relevant. When calculating
 ** relevance, query term instances in the 'title' column are given twice the
 ** weighting of those in the 'content' column.
 **
 **     SELECT docid FROM documents
 **     WHERE documents MATCH <query>
 **     ORDER BY rank(matchinfo(documents), 1.0, 0.5) DESC
 */
static void rankfunc(sqlite3_context * pCtx, int nVal, sqlite3_value ** apVal) {
    int * aMatchinfo; /* Return value of matchinfo() */
    int nMatchinfo; /* Number of elements in aMatchinfo[] */
    int nCol = 0; /* Number of columns in the table */
    int nPhrase = 0; /* Number of phrases in the query */
    int iPhrase; /* Current phrase */
    double score = 0.0; /* Value to return */
    
    assert(sizeof(int) == 4);
    
    /* Check that the number of arguments passed to this function is correct.
     ** If not, jump to wrong_number_args. Set aMatchinfo to point to the array
     ** of unsigned integer values returned by FTS function matchinfo. Set
     ** nPhrase to contain the number of reportable phrases in the users full-text
     ** query, and nCol to the number of columns in the table. Then check that the
     ** size of the matchinfo blob is as expected. Return an error if it is not.
     */
    if (nVal < 1) {
        sqlite3_result_error(pCtx, "no args passed to function rank()", -1);
        return;
    }
    
    aMatchinfo = (unsigned int *) sqlite3_value_blob(apVal[0]);
    nMatchinfo = sqlite3_value_bytes(apVal[0]) / sizeof(int);
    if (nMatchinfo >= 2) {
        nPhrase = aMatchinfo[0];
        nCol = aMatchinfo[1];
    }
    if (nMatchinfo != (2 + 3 * nCol * nPhrase)) {
        sqlite3_result_error(pCtx,
                             "invalid matchinfo blob passed to function rank()", -1);
        return;
    }
    
    // +1 for matchinfo arg
    if (nVal != (1 + nCol)) {
        char *msg = sqlite3_mprintf("invalid args (expected: %d, got: %d) passed to function rank()", nCol + 1, nVal);
        sqlite3_result_error(pCtx, msg, -1);
        sqlite3_free(msg);
        return;
    }
    
    /* Iterate through each phrase in the users query. */
    for (iPhrase = 0; iPhrase < nPhrase; iPhrase++) {
        int iCol; /* Current column */
        
        /* Now iterate through each column in the users query. For each column,
         ** increment the relevancy score by:
         **
         **   (<hit count> / <global hit count>) * <column weight>
         **
         ** aPhraseinfo[] points to the start of the data for phrase iPhrase. So
         ** the hit count and global hit counts for each column are found in
         ** aPhraseinfo[iCol*3] and aPhraseinfo[iCol*3+1], respectively.
         */
        int * aPhraseinfo = & aMatchinfo[2 + iPhrase * nCol * 3];
        for (iCol = 0; iCol < nCol; iCol++) {
            int nHitCount = aPhraseinfo[3 * iCol];
            int nGlobalHitCount = aPhraseinfo[3 * iCol + 1];
            double weight = sqlite3_value_double(apVal[iCol + 1]);
            if (nHitCount > 0) {
                score += ((double) nHitCount / (double) nGlobalHitCount) * weight;
            }
        }
    }
    
    sqlite3_result_double(pCtx, score);
    return;
    
    /* Jump here if the wrong number of arguments are passed to this function */
wrong_number_args:
    sqlite3_result_error(pCtx, "wrong number of arguments to function rank()", -1);
}
