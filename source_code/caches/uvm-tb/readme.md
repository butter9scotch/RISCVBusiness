# Caches UVM Testbench Setup Guide

### Build/Run Params
Everything related to building and running the uvm testbench is handled by the run.py script. To view the parameters:
```bash
run.py -h
```
`Note:` you may need to change permissions of the run.py file:
```bash
chmod u+x run.py
```

## Design Notes:
- Need to drive byte_en to memory, at least full word (4'b1000)
- evicting the right data but wrong address


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
    - need to write data back to memory on eviction
  - TODO: ensures that snoops to cache work properly (vague because I still don't really know what this means...)
  - ensure that no mem bus transactions occur without ren/wen
    - //TODO: this will probably change if we do prefetching
      - PrRd A // miss
        - BusRead A Block
      - Prefetch B // no cpu req
        - BusRead B Block
      - PrRd C (**) //hit
      - Issues:
        - if (**) is PrRd B
          - stall until cpu_ap sees PrRd B
          - cache_model expected miss
          - mem_fifo will hold the expected prefetched data
            - not incorrect but timing is backwards
        - if (**) is PrRd C


## Extension Ideas:
- Timing Agent
  - responsible for monitoring both buses like end2end and checking if the correct number of cycles for hits/misses
- Update Nominal Sequence to have better distribution of reads/writes
- end to end checker update
  - all async ap for cpu_tx, mem_tx (req and resp) -> gives us the start and stop time of a transaction
  - cpu_tx_start()
    - check words_read to determine if there were prev txns
      - handle txns if detected
        - prefecting --> update mem model
        - coherence --> update mem model, need to check end 2 end for bus -> cache -> bus for snoop resp!
  - mem_tx() -> no need for start or stop?
    - words_read++
    - addr_history.push(new_addr)
    - update cache model
      - cache_model.valid_block(base_addr) --> add this to cache model
  - cpu_tx_end()
    - check that words_read % block_size == 0 --> valid block size
    - check that hit/miss --> quiet/loud bus
    - check addresses map to valid blocks (all four addrs are in same block)
  - TODO: we can probably get rid of the txn.cycle value if we use this scheme
  - Summary:
    - coherence monitor sends snoop transactions out to subscribers
      - initialially this will be a monitor that never sends out messages (dummy monitor)
    - memory monitor simply a generic bus monitor
    - end to end has ap write functions for:
      - cpu_req -> calls cpu_tx_start()
      - cpu_resp -> calls cpu_tx_end()
      - mem_resp -> calls mem_tx()
      - coherence req? -> for now just have generic coherence ap
      - coherence resp?


## Sequences:
A = [A1, A2, A3, A4]
B = [B1, B2, B3, B4]

write A1, 0x1234
read A2           --> what data do we expect? {0xBAD0, addr[15:0]}? 
...
block A is evicted from cache
...
read A1           --> expect 0x1234