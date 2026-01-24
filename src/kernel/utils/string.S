.include "riscv.inc"

.section .text
.global memset

# fill memory with value
memset: # a0 = dest, a1 = value, a2 = size; modified: t0
    push a0 # save original argument registers
    li t0, 0
_memset_loop:
    sb a1, 0(a0) # store value to destination address
    inc a0 # increment destination address
    inc t0 # increment counter
    bne t0, a2, _memset_loop # loop until counter is equal to size
_memset_end:
    pop a0 # restore original argument registers
    ret

# copy source size bytes to destination
memcpy: # a0 = dest, a1 = src, a2 = size; modified: t0
    push a0 # save original argument registers
    li t0, 0
_memcpy_loop:
    push t0 # save temporary register to shrink registers use
    lb t0, 0(a1) # load value from source address
    sb t0, 0(a0) # store value to destination address
    pop t0 # restore temporary register
    inc a0 # increment destination address
    inc a1 # increment source address
    inc t0 # increment counter
    bne t0, a2, _memcpy_loop # loop until counter is equal to size
_memcpy_end:
    pop a0 # restore original argument registers
    ret
