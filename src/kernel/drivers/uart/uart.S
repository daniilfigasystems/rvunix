.include "riscv.inc"
.include "memlayout.inc"

.section .text
.global uart_write
.global uart_writestring

# Write value to UART
uart_write: # a0 = value; modified: t0
    svra # save return address
    li t0, MM_UART_IO # load base address of UART
    sb a0, 0(t0) # write value to UART
    ldra # restore return address
    ret

# Write string to UART
uart_writestring: # a0 = string; modified: t0
    svra # save return address
    push a0 # save original argument registers
    mv t0, a0
_uart_writestring_loop:
    lb a0, 0(t0) # load byte from string
    beqz a0, _uart_writestring_end # if byte is equal to zero, stop printing
    push t0 # save affected registers
    call uart_write # write byte to uart
    pop t0 # restore registers
    inc t0 # switch to next byte of string
    j _uart_writestring_loop # loop until string ends
_uart_writestring_end:
    pop a0 # restore original argument registers
    ldra # restore return address
    ret
