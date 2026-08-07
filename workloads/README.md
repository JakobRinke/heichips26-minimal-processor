# Not a NAND Device - Assembly Specification
The assembly programmer has 3 instructions available.

## jmpz
```
; jmpz Ra #imm
; Jump If Zero: If value in register Ra is zero, jump program counter by #imm
```
## addi
```
; addi Ra Rb #imm
; Add Immediate: Rb=Ra+#imm, value of Rb is set to value of Ra added with #imm  
```
## swap
```
; swap Ra Rb
; Swap: Swap value in register Ra with a value at memory adress in register Rb
```
