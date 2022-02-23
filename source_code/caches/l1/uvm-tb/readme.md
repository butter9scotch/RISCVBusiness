# Caches UVM Testbench Setup Guide

## Makefile:
- make: builds and runs tb in terminal only mode
- make gui: build and runds tb in gui mode
- make build: build tb
- make run: runs QuestaSim in terminal only mode
- make help: prints the available commands
- make clean: remove build outputs from file structure

### Makefile Params
- TESTCASE: selects which test to run from the `tests/` folder
- VERBOSITY: selects UVM verbosity for prints 
    - UVM_NONE
    - UVM_LOW
      - actual and expected values for scoreboard errors
      - success msg for data matches
    - UVM_MEDIUM
      - actual and expected values for all scoreboard checks
      - predictor default values for non-initialized memory
    - UVM_HIGH
      - all uvm transactions detected in monitors, predictors, scoreboards 
      - predictor memory before:after
    - UVM_FULL
      - all connections between analysis ports
      - all agent sub-object instantiations
      - all virtual interface accesses to uvm db
    - UVM_DEBUG

## TB Hierarchy:
```
tb_caches_top.sv
|_ tests/raw_test.svh
   |_ env/cache_env_config.svh
   |_ env/cache_env.svh
      |_ cpu_agent/cpu_agent.svh
      |  |_ cpu_agent/cpu_driver.svh
      |  |_ cpu_agent/cpu_monitor.svh
      |     |_ generic_bus_components/bus_monitor.svh
      |
      |_ cpu_agent/cpu_predictor.svh
      |  |_ generic_bus_components/bus_predictor.svh
      |
      |_ cpu_agent/cpu_scoreboard.svh
      |  |_ generic_bus_components/bus_scoreboard.svh
      |
      |_ mem_agent/mem_agent.svh
      |  |_ mem_agent/mem_monitor.svh
      |     |_ generic_bus_components/bus_monitor.svh
      |
      |_ mem_agent/mem_predictor.svh
      |  |_ generic_bus_components/bus_predictor.svh
      |
      |_ mem_agent/mem_scoreboard.svh
      |  |_ generic_bus_components/bus_scoreboard.svh
      |
      |_ end2end/end2end.svh
```
## Design Notes:
- Need to drive byte_en to memory, at least full word (4'b1000)

## TODO
- [ ] figure out how to deal with compulsory miss to Memory BFM. What value should we predict?
  - [ ] how to randomize what values we have in default memory and still predict
- [ ] add a random seed option for random generator
- [ ] env - config
  - [ ] shared variables between objects
- [ ] figure out how to deal with writes/reads to words brought in from separate word in block r/w miss
  - [ ] global memory?
- [ ] test a byte address (lower bits non-zero) with the byte enable not matching


## Responsibilities:
- CPU Agent
  - ensure reads after a write (at any time in the past) returns the same data
  - //TODO: in the future need a way to update memory model on coherence interactions
- Memory Agent
  - ensure reads after a write (at any time in the past) returns the same data
- End to End Checker
  - keeps track of data in cache
    - check cpu bus for modifying data in cache
    - check mem bus for adding data to cache on read
    - check mem bus for removing data from cache on write
  - ensure hit doesn't propogate to mem bus
  - ensure miss propogates with correct addr to mem bus
    - need to read data from same address
    - may need to write data back to memory on eviction
      - //TODO: FIGURE OUT HOW TO HANDLE EVICTION
        - do we care about what data is evicted?
        - can we simply note down that data has been evicted in our memory model?
  - ensure that no mem bus transactions occur without ren/wen
    - //TODO: this will probably change if we do prefetching



## Sequences:
A = [A1, A2, A3, A4]
B = [B1, B2, B3, B4]

write A1, 0x1234
read A2           --> what data do we expect? {0xBAD0, addr[15:0]}? 
...
block A is evicted from cache
...
read A1           --> expect 0x1234