# HeiChips 2026 -- NAND (NOT A NAND CHIP)
## A minimalist dualcore CPU with Memorymanagement and DMA support
It works on 200um x 200um and can have a clock frequency of up to 300 MHz
![CPU explained](CPU_explained.png)


### ISA
The CPU only does support 3 Instructions:
  - ADDI (Add Immediate)
  - JMPZ (Jump if Register is Zero)
  - SWAP (Swap Register Value with something in the Memory)

More info on the ISA is ![here](workloads/README.md)

And a example assembly program is ![here](workloads/assembly/simple_addition.nand)


### CPU Architecture
Here is a simple Architecture Stream.
![CPU Architecture](cpu_arch.drawio.png)

The Memory Communicatior manages the memory Access and makes each CPU able to communicate with the MMU


### TOP Level Architecture
TODO
