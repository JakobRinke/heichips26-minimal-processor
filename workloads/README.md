# Not a NAND Device - Assembly Specification
The assembly programmer has 3 instructions available.

## jmpz
```
; jmpz R1 #imm
; Jump If Zero: If value in register R1 is zero, jump program counter by #imm
```
## addi
```
; addi R2 R1 #imm
; Add Immediate: R2=R1+#imm, value of R2 is set to value of R1 added with #imm  
```
## swap
```
; swap R1 R2
; Swap: Swap value in register R1 with a value at memory adress in register R2
```
