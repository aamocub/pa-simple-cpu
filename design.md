# Design document

We need to decide all the components, how they work (input and output signals, as well as internal logic) and how they are connected to each other.

## 3 Main sections of our CPU
- Frontend: In charge of PC address generation as well as dealing with branch prediction
- Backend: In charge of executing the instructions received by the frontend
- Memory Subsystem: In charge of dealing with cache accesses and memory accesses

## Rubric
#### Basic Pipeline
- [ ] 5 stage pipe
- [ ] bypassing
- [ ] icache
- [ ] dcache
- [ ] common mem
- [ ] LDW works?
- [ ] ADD works?
- [ ] Branch works?
- [ ] JALx works?
- [ ] STW works?
- [ ] 5stage mul
- [ ] MUL works?
- [ ] LB supported?
- [ ] SB supported?
- [ ] store buffer
- [ ] store buffer
- [ ] sb drain
- [ ] bypass form sb
- [ ] Virtual Mem
- [ ] itlb
- [ ] dtlb
- [ ] TLB miss
- [ ] tlbwrite
- [ ] ptw
#### Exceptions / Supervisor
- [ ] superv/user
- [ ] ROB or HF
- [ ] iret
- [ ] csrrw / rm support
- [ ] exceptions
- [ ] OS Code
#### Results
- [ ] Buffer Sum CPI
- [ ] MemCopy CPI
- [ ] Matrix Multipliy CPI
#### Extra
- [ ] Extra: OoO
- [ ] Extra: Branch Predictor
- [ ] Extra: Superscalar

## Components

- [ ] PC register
- [ ] PC register adder +4
        - input:
                - current pc (32 bits)
        - output:
                - new pc (32 bits)
- [ ] PC Mux Selector
        - input:
                - current pc +4
                - branch pc
                - exception pc
                - control signal
        - output:
                - next pc
- [ ] PIPELINE REGISTERs
- [ ] Regfile
- [ ] ALU
- [ ] Memory:
        - input:
                - clk
                - rst
                - read port 1 (for instruction fetching):
                        - address
                        - en
                - read port 2 (for data fetching):
                        - address
                        - en
                - write port:
                        - address
                        - en
                        - data
        - output:
                - read port 1:
                        - address
                        - en
                - read port 2:
                        - address
                        - en

## How it works

What is the path of an instruction form the PC generation to the end of its execution?

Problems to resolve:
- [ ] Data dependencies between instructions
- [ ] Hazards (estructural and branch related)
- [ ] Virtual memory
- [ ] Cache management
- [ ] Exceptions
- [ ] Interrupts
- [ ] Out-of-Order execution (introduction of a Reorder Buffer and all the logic behind it)
- [ ] Branch prediction
- [ ] General Control logic that comes up