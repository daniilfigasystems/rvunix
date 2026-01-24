.include "memlayout.inc"

.section .text
.global uart_write

# write value to terminal
uart_write: # a0 = value; modified: t0
    li t0, MM_UART_IO # load base address of UART
    sb a0, 0(t0) # write value to terminal
    ret
