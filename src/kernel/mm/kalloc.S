.include "riscv.inc"
.include "memlayout.inc"

.section .text
.global kalloc_init
.global kalloc
.global kfree

# initialize memory managment
kalloc_init: # no arguments; modified: t0, t1, t2
    push a0 # save original argument registers
    push a1
    push a2
    li a0, 'a'
    callr uart_write # debugging stuff, will be removed in future
    la t0, _kern_end
    li t1, PAGE_SIZE
    add t0, t0, t1 # calculate first address after kernel end
    li t1, MM_PHYSTOP # set end to physical memory end
    li t2, 0
    mv a0, t0
    li a2, PAGE_SIZE # set step size to page size (4k)
_kalloc_init_loop:
    mv a0, t0
    mv a1, zero
    push t0 # save affected registers
    callr memset # zero out memory to get rid of garbage data
    pop t0 # restore registers
    push t0 # save affected registers
    add t0, t0, a2 # switch to another page
    mv a1, t0 # save next address
    pop t0 # restore registers
    sd a1, 0(t0) # store next address value to current address
    mv t0, a1 # set current address to next address
    bne t0, t1, _kalloc_init_loop
_kalloc_init_end:
    la t1, current_address
    la t0, _kern_end
    li t2, PAGE_SIZE
    add t0, t0, t2 # calculate first page after kernel
    sd t0, 0(t1) # store first page address in current address variable
    pop a2 # restore original argument registers
    pop a1
    pop a0
    ret

# allocate one page of memory
kalloc: # no arguments; modified: t0, t1, a0
    la t0, current_address
    ld t1, 0(t0) # load current address
    push t0 # save affected registers
    ld t0, 0(t1) # load next address from current address
    pop a0 # restore registers
    sd t0, 0(a0) # save next address to current address variable
    mv a0, t1
    ret

# free page located at addr (addr must be page aligned)
kfree: # a0 = allocated memory address; modified: t0, t1
    li t0, PAGE_SIZE
    rem t0, a0, t0 # reminder from address division must be zero
    bnez t0, _kfree_end # if address isn't page aligned then return
    la t0, current_address
    ld t1, 0(t0) # load current address
    sd a0, 0(t0) # save addr to current address
    sd t1, 0(a0) # save current address to addr
_kfree_end:
    ret

.section .data

current_address:
    .long 0x0000000000000000 # current address that free
