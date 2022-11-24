# notifies the state of a reasoner
uint64 reasoner_id # the reasoner whose state has changed
uint8 REASONING = 0
uint8 INCONSISTENT = 1
uint8 IDLE = 2
uint8 EXECUTING = 3
uint8 ADAPTING = 4
uint8 FINISHED = 5
uint8 DESTROYED = 6
uint8 deliberative_state # the new reasoner state