# AerialS

The Robot Operating System ([ROS](https://www.ros.org/)) is a set of software libraries and tools that help you build robot applications. ROS processes are represented as nodes in a graph structure, connected by edges called _topics_. Such nodes can pass _messages_ to one another through _topics_, make _service calls_ to other nodes, provide a _service_ for other nodes, or set or retrieve shared data from a communal database called the parameter server. 

This folder contains a ROS package, called _AerialS_, defining some messages and services for interfacing a deliberative tier and a reactive tier. Details of the passed messages, of the provided services expected of the expected one are provided below.

## Creating reasoners

In order to create a new reasoner, the deliberative tier should provide a service called `reasoner_builder`. The service type, called `ReasonerBuilder`, is structured as follows:

```
string[] domain_files
string[] requirements
---
uint64 reasoner_id
bool consistent
```

The service, specifically, is invoked with an array of domain models (`domain_files`) and an array of planning problems (`requirements`), returning, in a non-blocking way, the id (`reasoner_id`) of the just created reasoner and a boolean (`consistent`) which indicates whether no trivial inconsistencies have been detected in the planning problem.

It is worth noting that a call to this service initiates a potentially lengthy process for resolving the communicated planning problem. The result of the reasoning process is hence subsequently communicated through a ROS message on a specific topic.

## Detecting the reasoners' states changes

The reasoners' states changes can be detected by subscribing to the `deliberative_state` topic. The state of the reasoners is communicated through a `DeliberativeState` message which has the following structure:

```
uint64 reasoner_id
uint8 REASONING = 0
uint8 INCONSISTENT = 1
uint8 IDLE = 2
uint8 EXECUTING = 3
uint8 ADAPTING = 4
uint8 FINISHED = 5
uint8 DESTROYED = 6
uint8 deliberative_state
```

Intuitively, the message notifies the interested subscribers that the `reasoner_id` planner is currently in the `deliberative_state` state. Creating a new reasoner puts it into a `REASONING` state, attempting to solve the problem defined in the previous `reasoner_builder` call. In case the planning problem has no solution the reasoner passes into the `INCONSISTENT` state and, from that moment on, it can only be `DESTROYED`. If, on the other hand, a solution is found, the reasoner goes into the `IDLE` state, waiting for a `START` execution command by the reactive tier, or, in case the solution contains non planned activities, into a `FINISHED` state. Upon the arrival of the `START` command, the reasoner passes into the `EXECUTING` state, remaining there, executing the plan, until further execution commands by the reactive tier are received or adaptations are requested. In case a `PAUSE` execution command is received, the reasoner goes back into the `IDLE` state, pausing the execution of the plan. Whenever an adaptation request is received, the reasoner goes into an `ADAPTING` state, managing the adaptation and returning, when done, into the previous execution state (either `IDLE` or `EXECUTING`) or, if it is not possible manage the required adaptations, into an `INCONSISTENT` state. Finally, once all the scheduled tasks have been executed, the reasoner jumps into a `FINISHED` state.

The following figure shows the possible state transitions.

```mermaid
stateDiagram-v2
    direction LR
    [*] --> REASONING
    DESTROYED --> [*]
    REASONING --> IDLE
    REASONING --> INCONSISTENT
    REASONING --> FINISHED
    REASONING --> DESTROYED
    IDLE --> ADAPTING
    IDLE --> EXECUTING
    IDLE --> DESTROYED
    ADAPTING --> IDLE
    ADAPTING --> EXECUTING
    ADAPTING --> INCONSISTENT
    ADAPTING --> FINISHED
    ADAPTING --> DESTROYED
    EXECUTING --> ADAPTING
    EXECUTING --> FINISHED
    EXECUTING --> DESTROYED
    FINISHED --> ADAPTING
    FINISHED --> DESTROYED
    INCONSISTENT --> DESTROYED
```

## Starting the execution

Once a consistent solution has been found, the reasoner puts itself into the `IDLE` state, waiting for the invocation from the reactive tier of a service, called `executor`, that changes the execution state of the generated plan. The service, whose type is called `Executor`, has the following structure:

```
uint64 reasoner_id
uint8 START = 0
uint8 PAUSE = 1
uint8 command
string[] notify_start
string[] notify_end
---
uint8 new_state
```

The service, specifically, is invoked with the id (`reasoner_id`) of the reasoner whose plan is waiting for execution. The `command` value assumes either the `START` or the `PAUSE` value, requiring the reasoner to start or pause the execution. In case the execution is being started, a couple of arrays indicate the predicates which, before being started (ended), require the approval of the reactive tier.

## Describing tasks

Much of the information exchanged between the deliberative tier and the reactive tier involves tasks. For this reason we have defined a ROS data type, called `Task`, with the following structure:

```
uint64 reasoner_id
uint64 task_id
string task_name
string[] par_names
string[] par_values
```

Each task, in particular, consists of the id of the reasoner who generated it (`reasoner_id`), an id that identifies the task (`task_id`), the name of the task (`task_name`), and a set of parameter names (`par_names`) with their respective assigned values (`par_values`).

## Checking the executability and executing the tasks

During execution, for those types of tasks for which the notification of the start (end) has been requested by the `start_execution` service, the `can_start` (`can_end`) service, whose type is called `TaskExecutor` and having the following structure, is invoked by the deliberative tier to the reactive tier.

```
Task task
---
bool success
rational delay
```

The service, intuitively, asks for the start (end) of a task, returning a boolean (`success`) indicating whether the task can be started (ended). In case the task cannot be started (ended), it is possible to provide the indicative amount of time (`delay`) before the task can be started (ended). It is worth noting that the permission to start (end) the execution of a task, offered by the reactive tier, does not directly translate into its starting (ending). Suppose, for example, that by the modeled domain two tasks must start at the same time but, during the execution, only one of them is considered executable by the reactive tier, the latter could return false to just one of them, yet both tasks, compatibly with the other involved constraints, should be delayed. Before communicating the start (end) of a task, in particular, the executor requests permission to the reactive tier, delaying, with the propagation of the involved constraints, the start (end) of those tasks for which permission is not granted. Only those tasks which should have started (ended) and which have not been delayed can then be executed (terminated). The beginning (ending) of the execution of a task is communicated to the reactive tier, on a different channel, through the `start_task` (`end_task`) service having the same type.

## Delaying and extending tasks

The start (end) of an activity can be delayed due to unforeseen events. If the reactive tier recognizes the need to delay the execution (end) of a task, it can communicate it to the deliberative tier, in advance, so as to promptly adapt the plan. This can be done through the `task_delayer` (`task_extender`) service, whose type is called `TaskDelayer`, having the following structure:

```
Task task
Rational delay
---
bool delayed
```

This service demands the deliberative tier to delay (extend) the task `task` by a `delay` amount. Since the adaptation can take a long time, possibly bringing the deliberative tier into the `ADAPTING` state, the service promptly returns the `delayed` boolean indicating, in case no trivial inconsistencies have been recognized, whether the activity has been delayed (extended).

## Closing tasks

The notification of the termination of an activity can be used in those cases where the termination does not create problems (for example, to turn off a camera and thus save energy). In all other cases, the deliberative tier expects the reactive tier to communicate the termination of the task. This can be done through the `task_closer` service, whose type is called `TaskCloser`, having the following structure:

```
Task task
bool success
---
bool closed
```

The service, intuitively, invoked by the reactive tier, communicates the end of the `task` task. The `success` field is used to communicate if the task execution was successful. If not, in particular, the corresponding token is removed from the current plan and the plan adaptation procedure, to ensure the maintenance of the causal constraints, is invoked.

## Dynamically adding new requirements

As we have seen in the previous sections, the system offers, during execution, the possibility of dynamically and incrementally adding new requirements to the planning problem. This service is called `requirement_manager`. It has a type called `RequirementManager` with the following structure:

```
uint64 reasoner_id
string[] requirements
---
bool consistent
```

The service, intuitively, asks for the addition of some `requirements` to the reasoner `reasoner_id`, returning, as in the case of the creation of a new reasoner, a boolean (`consistent`) which indicates whether any trivial inconsistencies have been detected in the planning problem. The service, in a non-blocking way, initiates the potentially lengthy process of resolving the planning problem, communicating the result through the `deliberative_state` message.

## Destroying reasoners

The last ROS service considered concerns the destruction of a reasoner. The service, called `destroy_reasoner`, has a type called `ReasonerDestroyer` which has the following structure:

```
uint64 reasoner_id
---
bool destroyed
```

The service, intuitively, destroys the no longer needed reasoner `reasoner_id`, releasing all the resources assigned to it, returning a boolean (`destroyed`) indicating whether the procedure was successful.
