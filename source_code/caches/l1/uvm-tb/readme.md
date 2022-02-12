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
    - UVM_MEDIUM
    - UVM_HIGH
    - UVM_FULL
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
