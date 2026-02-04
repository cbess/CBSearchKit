## Project Overview

CBSearchKit is an Objective-C full-text search library for iOS (13.0+) and macOS (10.15+) built on SQLite FTS3/4/5 via FMDB.

## Build & Test Commands

```bash
swift build
swift test
```

## Architecture

The library has three core classes and one protocol, all in `Sources/CBSearchKit/`:

- **`CBSIndexItem` protocol** (`CBSIndexDocument.h`) — Any object conforming to this protocol can be indexed. Key methods: `indexItemIdentifier`, `indexTextContents`, `canIndex`, `indexItemType`, `indexMeta`, plus `willIndex`/`didIndex` lifecycle hooks.

- **`CBSIndexDocument`** — Concrete `CBSIndexItem` implementation with simple properties. Conforms to `NSCopying`.

- **`CBSIndexer`** — Manages the SQLite FTS virtual table. Creates/opens databases (in-memory via `nil` name, or file-backed in Caches directory). All indexing operations (add, update, remove) run asynchronously on a private serial GCD queue (`indexQueue`). Bulk operations use FMDB transactions. Supports FTS3/4/5 engine selection via `+setFTSEngineVersion:` (must be called before indexing).

- **`CBSSearcher`** — Performs FTS MATCH queries against an indexer's database. Search results are delivered on the **main thread**. Supports relevance ordering via a custom SQLite ranking function (`sqlite3_rank_func.h`), pagination with offset/limit, filtering by `itemType`, and a factory handler (`setItemFactoryHandler:`) to transform results into custom domain objects.

- **`CBSSearchManager`** — Placeholder wrapper around CBSIndexer; not yet fully utilized.

### FTS Table Schema
```sql
CREATE VIRTUAL TABLE cbs_fts USING fts4 (
    item_id, contents, item_type, item_meta UNINDEXED
)
```
Metadata (`indexMeta`) is stored as JSON but is not searchable (UNINDEXED).

### Threading Model
- Indexer operations: async on private serial `indexQueue`, completion handlers fire on `indexQueue`
- Search operations: async on private `searchQueue`, completion handlers fire on **main thread**
- Both use weak self captures to handle early deallocation

### Custom Ranking
`Sources/CBSearchKit/sqlite3_rank_func.h` implements a custom SQLite function using `matchinfo()` data with configurable column weights (term frequency / document frequency scoring).

## Dependencies

- **FMDB** (2.7.5+) — Objective-C SQLite wrapper (provides `FMDatabaseQueue`), via Swift Package Manager

## Tests

Tests are in `Tests/CBSearchKitTests/`:
- `CBSIndexerTests.m` — 4 tests: indexing, item removal, optimize, reindex
- `CBSSearcherTests.m` — 5 tests: search, update, custom index items via factory handler, limit/offset
- `CBSCustomIndexDocument` — Test helper implementing `CBSIndexItem` for custom object tests
- All tests use in-memory databases (`initWithDatabaseNamed:nil`)
