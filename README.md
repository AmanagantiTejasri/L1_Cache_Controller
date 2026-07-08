# L1_Cache_Controller
## Overview
Cache memory is a small and high-speed memory located between the processor and main memory. 
It stores frequently accessed data and instructions to reduce the average memory access time.

Cache controller is the hardware unit responsible for managing communication between the 
processor, cache memory, and main memory.
It handles CPU read/write requests, detects cache hits/misses and controls data transfer 
between the cache and main memory.
## Project Details
Implemented an L1 Cache Controller using Verilog HDL. The controller logic is designed as
Finite State Machine (FSM) to handle CPU requests,cache hit/miss detection,cache refill, 
write-back and responding to CPU operations.
The design includes separate storage for cache data, tags, valid bits, dirty bits, and LRU 
information.It uses 2-way set associativity and Critical Word First (CWF) refill technique 
for efficient cache operation. The functionality is verified using Verilog testbenches 
covering different cache scenarios.
# Cache configuration
<img width="605" height="232" alt="image" src="https://github.com/user-attachments/assets/5d375e57-f2cb-4cac-a230-6acf0276fe6a" />

## Features

*2-way set associative cache
* Write-back policy with dirty bit
* Write allocate policy
* Least Recently Used (LRU) replacement policy
* Critical Word First (CWF) refill
* 6-state FSM based cache controller



