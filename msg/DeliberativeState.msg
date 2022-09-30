# notifies the state of a reasoner
uint64 reasoner_id # the reasoner whose state has changed
uint8 REASONING = 0
uint8 INCONSISTENT = 1
uint8 STOPPED = 2
uint8 PAUSED = 3
uint8 EXECUTING = 4
uint8 ADAPTING = 5
uint8 FINISHED = 6
uint8 DESTROYED = 7
uint8 deliberative_state # the new reasoner state