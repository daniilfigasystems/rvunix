.include "riscv.inc"
.include "timer.inc"

.section .text
.global timer_handler
.global timer_wait
.global timer_init

# Timer interrupt handler
timer_handler: # no arguments; modified: t0, t1
    svra # save return address
    la t0, timer_ticks # load timer tick counter variable address
    ld t1, 0(t0) # load timer tick counter value
    inc t1 # increment tick counter
    sd t1, 0(t0) # store adjusted tick counter value
    la t0, timer_freq # load timer frequency variable address
    ld t0, 0(t0) # load saved timer frequency for adjust
    csrr t1, time # read timer register
    add t0, t1, t0 # adjust timer compare for next interrupt
    csrw stimecmp, t0 # write calculated timer counter value
    ldra # restore return address
    ret

# Wait for n ticks
timer_wait: # a0 = ticks count; modified: t0, t1, t2
    svra # save return address
    la t0, timer_ticks # load timer tick counter variable address
    ld t1, 0(t0) # load timer tick counter value
    add t2, t1, a0 # calculate destination tick counter value
_timer_wait_loop:
    ld t1, 0(t0) # load new timer tick counter value
    blt t1, t2, _timer_wait_loop # loop until new timer tick counter value is less than calculated destination timer tick counter value
_timer_wait_end:
    ldra # restore return address
    ret

# Initialize RISC-V timer
timer_init: # a0 = freq; modified: t0
    svra # save return address
    la t0, timer_freq
    sd a0, 0(t0) # store timer frequency for future adjusting
    li t0, TIMER_IRQ_MASK # bit 5 of SIE is RISC-V timer interrupt bit
    csrs sie, t0 # enable timer interrupt
    csrr t0, time # read timer register
    add t0, t0, a0 # adjust timer compare for next interrupt
    csrw stimecmp, t0 # write calculated timer counter value
    ldra # restore return address
    ret

.section .bss

timer_freq:
    .quad 0x0000000000000000 # timer frequency

timer_ticks:
    .quad 0x0000000000000000 # timer passed ticks

.section .rodata

timer_int_msg:
    .asciz "timer: timer interrupt fired\n"
