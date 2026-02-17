# sci_tercen_context API Reference

## Context creation

| Function | Mode | Input |
| -------- | ---- | ----- |
| `OperatorContext.create(serviceFactory: f, taskId: id)` | Production | taskId from URL |
| `OperatorContextDev(serviceFactory: f, workflowId: w, stepId: s)` | Dev | workflowId + stepId |

## Data selection (all return `Future<Table>`)

| Method | Fetches | Empty names behavior |
| ------ | ------- | -------------------- |
| `ctx.select(names: [...])` | Main data (.y, .ci, .ri, values) | All non-system columns |
| `ctx.cselect(names: [...])` | Column dimension metadata | All non-system columns |
| `ctx.rselect(names: [...])` | Row dimension metadata | All non-system columns |
| `ctx.selectPairwise(names: [...])` | Pairwise data (scatter plots) | All non-system columns |

All accept optional `offset` (default 0) and `limit` (default -1 = all rows).

## Schemas (lazy-cached, `Future<Schema>`)

| Property | Source |
| -------- | ------ |
| `ctx.schema` | `tableSchemaService.get(query.qtHash)` |
| `ctx.cschema` | `tableSchemaService.get(query.columnHash)` |
| `ctx.rschema` | `tableSchemaService.get(query.rowHash)` |

## Column names (`Future<List<String>>`)

| Property | Source |
| -------- | ------ |
| `ctx.names` | Main schema column names |
| `ctx.cnames` | Column dimension column names |
| `ctx.rnames` | Row dimension column names |

## Visual metadata

| Property | Returns |
| -------- | ------- |
| `ctx.colors` | `Future<List<String>>` — color factor names |
| `ctx.labels` | `Future<List<String>>` — label factor names |
| `ctx.errors` | `Future<List<String>>` — error factor names |
| `ctx.xAxis` | `Future<List<String>>` — X-axis factor names |
| `ctx.yAxis` | `Future<List<String>>` — Y-axis factor names |
| `ctx.chartTypes` | `Future<List<String>>` — chart type per axis query |
| `ctx.pointSizes` | `Future<List<int>>` — point size per axis query |

## Data shape

| Property | Returns |
| -------- | ------- |
| `ctx.isPairwise` | `Future<bool>` — column and row names overlap |
| `ctx.hasXAxis` | `Future<bool>` — main schema has `.x` column |
| `ctx.hasNumericXAxis` | `Future<bool>` — `.x` is type `double` |

## Operator properties

| Method | Returns |
| ------ | ------- |
| `ctx.opStringValue('name', defaultValue: '')` | `Future<String>` |
| `ctx.opDoubleValue('name', defaultValue: 0.0)` | `Future<double>` |
| `ctx.opIntValue('name', defaultValue: 0)` | `Future<int>` |
| `ctx.opBoolValue('name', defaultValue: false)` | `Future<bool>` |
| `ctx.opValue<T>(name: ..., converter: ..., defaultValue: ...)` | `Future<T>` (generic) |

## Namespace

| Method/Property | Returns |
| --------------- | ------- |
| `ctx.namespace` | `Future<String>` — operator namespace |
| `ctx.addNamespace(['col1', '.ci'])` | `Future<Map<String, String>>` — prefixed names |

## Task lifecycle

| Method | Use |
| ------ | --- |
| `ctx.log('message')` | Log to Tercen UI |
| `ctx.progress('msg', actual: n, total: m)` | Report progress |
| `ctx.save(OperatorResult)` | Save full result |
| `ctx.saveTable(Table)` | Save single table |
| `ctx.saveTables(List<Table>)` | Save multiple tables |
| `ctx.saveRelation(List<JoinOperator>)` | Save join operators |
| `ctx.requestResources(nCpus: 4, ram: '8G')` | Request compute resources |

## Column helpers (static on AbstractOperatorContext)

| Method | Creates |
| ------ | ------- |
| `AbstractOperatorContext.makeInt32Column(name, data)` | Int32 column (Int32List + I32Values) |
| `AbstractOperatorContext.makeFloat64Column(name, data)` | Float64 column (Float64List + F64Values) |
| `AbstractOperatorContext.makeStringColumn(name, data)` | String column (CStringList + StrValues) |

## Other properties

| Property | Returns |
| -------- | ------- |
| `ctx.query` | `Future<CubeQuery>` — the underlying query |
| `ctx.task` | `Task?` — task object (null in dev mode) |
| `ctx.taskId` | `String?` — shorthand for `task?.id` |
| `ctx.serviceFactory` | `ServiceFactoryBase` — for advanced/direct access |

## File services (via ctx.serviceFactory)

| Method | Returns |
| ------ | ------- |
| `ctx.serviceFactory.fileService.download(id)` | `Stream<List<int>>` |
| `ctx.serviceFactory.fileService.listZipContents(id)` | `List<ZipEntry>` |
| `ctx.serviceFactory.fileService.downloadZipEntry(id, path)` | `Stream<List<int>>` |
