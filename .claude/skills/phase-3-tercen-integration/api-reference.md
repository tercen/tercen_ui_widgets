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

---

## Workflow execution services (Type 3 / Flow E)

Type 3 apps do not use OperatorContext. They access services directly via `ServiceFactory`.

### WorkflowService — `factory.workflowService`

| Method | Returns | Use |
| ------ | ------- | --- |
| `get(id)` | `Future<Workflow>` | Get workflow with all steps |
| `list(ids)` | `Future<List<Workflow>>` | Batch fetch workflows |
| `update(workflow)` | `Future<String>` (rev) | Save modified workflow (e.g. after setting properties) |
| `copyApp(workflowId, projectId)` | `Future<Workflow>` | Clone workflow into project |
| `getCubeQuery(workflowId, stepId)` | `Future<CubeQuery>` | Get step's cube query |

### TaskService — `factory.taskService`

| Method | Returns | Use |
| ------ | ------- | --- |
| `create(task)` | `Future<Task>` | Create task (e.g. `RunWorkflowTask`) |
| `runTask(taskId)` | `Future<void>` | Start task execution |
| `cancelTask(taskId)` | `Future<void>` | Cancel running task |
| `waitDone(taskId)` | `Future<Task>` | Block until task completes |
| `get(taskId)` | `Future<Task>` | Get task by ID |
| `setTaskEnvironment(taskId, List<Pair> env)` | `Future<void>` | Set environment variables before running |

### EventService — `factory.eventService`

| Method | Returns | Use |
| ------ | ------- | --- |
| `listenTaskChannel(taskId, start)` | `Stream<TaskEvent>` | WebSocket stream of all task events |
| `onTaskState(taskId)` | `Stream<TaskStateEvent>` | State changes only |

### TaskEvent subtypes

| Type | Properties | When |
| ---- | ---------- | ---- |
| `TaskLogEvent` | `.message` | Operator logs a message |
| `TaskProgressEvent` | `.message`, `.actual`, `.total` | Progress update |
| `TaskStateEvent` | `.state` (State) | Task state transition |
| `TaskDataEvent` | — | Data event (rare) |

### Task state classes

| Class | Properties | Meaning |
| ----- | ---------- | ------- |
| `InitState` | — | Created, not started |
| `PendingState` | — | Queued for execution |
| `RunningState` | — | Currently executing |
| `DoneState` | — | Completed successfully |
| `FailedState` | `.error`, `.reason` | Failed |

Check with `is`: `if (task.state is FailedState) { final f = task.state as FailedState; print(f.reason); }`

### RunWorkflowTask

| Property | Type | Description |
| -------- | ---- | ----------- |
| `projectId` | `String` | Target project (inherited from ProjectTask) |
| `workflowId` | `String` | Workflow to run |
| `workflowRev` | `String` | Workflow revision |
| `stepsToRun` | `List<String>` | Step IDs to execute (empty = all) |
| `stepsToReset` | `List<String>` | Step IDs to reset before running |

### Workflow, Step, StepState

| Property | Type | Description |
| -------- | ---- | ----------- |
| `workflow.steps` | `List<Step>` | All steps in workflow |
| `workflow.links` | `List<Link>` | Step connections |
| `step.name` | `String` | Step display name |
| `step.id` | `String` | Step ID |
| `step.state` | `StepState` | Execution state |
| `step.state.taskId` | `String` | Task ID for this step's execution |
| `step.state.taskState` | `State` | Current state (InitState, DoneState, etc.) |
| `step.computedRelation` | `Relation` | Output data relation tree |

Cast steps: `if (step is DataStep) { ... }` — `DataStep` has `computedRelation`, `parentDataStepId`.

### PropertyValue

| Property | Type | Description |
| -------- | ---- | ----------- |
| `.name` | `String` | Property name |
| `.value` | `String` | Property value (always string, parse as needed) |

Access via `step.operatorRef.propertyValues` (List<PropertyValue>).

### FileService — `factory.fileService`

| Method | Returns | Use |
| ------ | ------- | --- |
| `upload(fileDoc, Stream<List<int>> bytes)` | `Future<FileDocument>` | Upload file to project |
| `append(fileDoc, Stream<List<int>> bytes)` | `Future<FileDocument>` | Append to existing file |
| `download(fileDocId)` | `Stream<List<int>>` | Download file content |

### ProjectService — `factory.projectService`

| Method | Returns | Use |
| ------ | ------- | --- |
| `get(id)` | `Future<Project>` | Get project by ID |
| `create(project)` | `Future<Project>` | Create new project |
| `cloneProject(id, targetProject)` | `Future<Project>` | Clone project |
| `findProjectByOwnerNameStream(startKeyOwner, endKeyOwner, startKeyName, endKeyName)` | `Stream<Project>` | List projects by owner |

### ProjectDocumentService — `factory.projectDocumentService`

| Method | Returns | Use |
| ------ | ------- | --- |
| `findWorkflowByProjectIdFolderStream(startKeyProjectId, endKeyProjectId, startKeyFolderId, endKeyFolderId)` | `Stream<Workflow>` | List workflows in project/folder |
| `findFileDocumentByProjectIdFolderStream(...)` | `Stream<FileDocument>` | List files in project/folder |
| `findSchemaByProjectIdFolderStream(...)` | `Stream<Schema>` | List schemas in project/folder |

### TableSchemaService — `factory.tableSchemaService`

| Method | Returns | Use |
| ------ | ------- | --- |
| `get(hash)` | `Future<TableSchema>` | Get schema (.columns, .nRows) |
| `list(ids)` | `Future<List<TableSchema>>` | Batch fetch schemas |
| `select(hash, columnNames, offset, limit)` | `Future<InMemoryTable>` | Read data from schema |

### Key data models

| Model | Key fields |
| ----- | ---------- |
| `Project` | `.id`, `.name`, `.acl.owner` |
| `Workflow` | `.id`, `.name`, `.projectId`, `.steps`, `.links`, `.rev` |
| `DataStep` | `.id`, `.name`, `.computedRelation`, `.state`, `.parentDataStepId` |
| `FileDocument` | `.id`, `.name`, `.dataUri`, `.size`, `.projectId` |
| `TableSchema` | `.id`, `.nRows`, `.columns` (List with `.name`, `.type`) |
| `InMemoryTable` | `.columns` (List with `.name`, `.values`) |
