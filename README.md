# sensu-plugins-mongodb-stats
Collect stats from server status and include/exclude metrics based on regex/lists

- help

```sh
$  ./metrics-mongodb-server-status.rb --help
Collect metrics from MongoDB server status. Use include and exclude list/regex to limit the metrics returned
You can use both lists and filters to restrict the metrics to collect
The processing order defaults to: list_include filter_include filter_exclude list_exclude -- but it can be managed using --filter_order
```

- Simple run with filters

```sh
$  ./metrics-mongodb-server-status.rb --filter-include '.*repl\..*,.*ops.*,.*plan.*' --filter-exclude '.*failed$,.*readersCreated$' --host localhost --port 27017 --prefix ${HOSTNAME}.a_random_prefix
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.commands.planCacheClear.total 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.commands.planCacheClearFilters.total 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.commands.planCacheListFilters.total 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.commands.planCacheListPlans.total 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.commands.planCacheListQueryShapes.total 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.commands.planCacheSetFilter.total 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.apply.batches.num 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.apply.batches.totalMillis 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.apply.ops 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.buffer.count 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.buffer.maxSizeBytes 268435456 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.buffer.sizeBytes 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.network.bytes 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.network.getmores.num 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.network.getmores.totalMillis 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.network.ops 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.preload.docs.num 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.preload.docs.totalMillis 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.preload.indexes.num 0 1476313862
miniserver.mydomain.a_random_prefix.standalone.other.miniserver.metrics.repl.preload.indexes.totalMillis 0 1476313862
```

- Run with filters and managing the order in which they are applied

```sh
$  ./metrics-mongodb-server-status.rb --filter_exclude '.*indexes.*' --filter_include '.*preload.*,.*Executor.*' --filter_order 'filter_exclude,filter_include,list_include,list_exclude' --host localhost --port 27017 --list_exclude 'metrics.queryExecutor.scannedObjects'
standalone.other.miniserver.metrics.queryExecutor.scanned 0 1476316515
standalone.other.miniserver.metrics.repl.preload.docs.num 0 1476316515
standalone.other.miniserver.metrics.repl.preload.docs.totalMillis 0 1476316515
```
