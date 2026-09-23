.include "riscv.inc"

.section .text
.global timer_handler
.global timer_init

# Timer interrupt handler
timer_handler: # no arguments; modified: t0, t1, a0
    svra # save return address
    la t0, timer_freq
    ld t0, 0(t0) # load saved timer frequency for adjust
    csrr t1, time # read timer register
    add t0, t1, t0 # adjust timer compare for next interrupt
    csrw stimecmp, t0 # write calculated timer counter value
    ldra # restore return address
    ret

# Initialize RISC-V timer
timer_init: # a0 = freq; modified: t0
    la t0, timer_freq
    sd a0, 0(t0) # store timer frequency for future adjusting
    li t0, 0x20
    csrs sie, t0 # enable timer interrupt
    csrr t0, time # read timer register
    add t0, t0, a0 # adjust timer compare for next interrupt
    csrw stimecmp, t0 # write calculated timer counter value
    ret

.section .bss

timer_freq:
    .quad 0x0000000000000000 # timer frequency

.section .rodata

timer_int_msg:
    .asciz "timer: timer interrupt fired\n"
