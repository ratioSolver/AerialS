# notifies the state of a reasoner
uint64 reasoner_id # the reasoner whose state has changed
uint8 CREATED = 0
uint8 REASONING = 1
uint8 INCONSISTENT = 2
uint8 IDLE = 3
uint8 EXECUTING = 4
uint8 FINISHED = 5
uint8 DESTROYED = 6
uint8 deliberative_state # the new reasoner state