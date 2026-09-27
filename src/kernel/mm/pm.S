.include "riscv.inc"
.include "memlayout.inc"

.section .text
.global pm_init
.global pm_page_allocate
.global pm_page_free

# Initialize memory managment
pm_init: # no arguments; modified: t0, t1, t2
    svra # save return address
    push a0 # save original argument registers
    push a1
    push a2
    la t0, _kern_end
    pgalignup t0, t0 # calculate first address after kernel end
    li t1, MM_PHYSTOP # set end to physical memory end
    li t2, 0
    mv a0, t0
    li a2, PAGE_SIZE # set step size to page size (4k)
_pm_init_loop:
    mv a0, t0
    mv a1, zero
    push t0 # save affected registers
    call memset # zero out memory to get rid of garbage data
    pop t0 # restore registers
    add a1, t0, a2 # switch to another page
    sd a1, 0(t0) # store next address value to current address
    mv t0, a1 # set current address to next address
    bne t0, t1, _pm_init_loop
_pm_init_end:
    la t1, current_address
    la t0, _kern_end
    pgalignup t0, t0 # calculate first page after kernel
    sd t0, 0(t1) # store first page address in current address variable
    pop a2 # restore original argument registers
    pop a1
    pop a0
    ldra # restore return address
    ret

# Allocate one page of memory
pm_page_allocate: # no arguments; modified: t0, t1, a0 (returns physical address of allocated memory here)
    svra # save return address
    la t0, current_address
    ld t1, 0(t0) # load current address
    beqz t1, _pm_page_allocate_end # if address is zero, we ran out of memroy
    push t0 # save affected registers
    ld t0, 0(t1) # load next address from current address
    pop a0 # restore registers
    sd t0, 0(a0) # save next address to current address variable
_pm_page_allocate_end:
    mv a0, t1
    ldra # restore return address
    ret

# Free page located at addr (addr must be page aligned)
pm_page_free: # a0 = allocated memory address; modified: t0, t1
    svra # save return address
    li t0, PAGE_SIZE
    rem t0, a0, t0 # reminder from address division must be zero
    bnez t0, _pm_page_free_end # if address isn't page aligned then return
    la t0, current_address
    ld t1, 0(t0) # load current address
    sd a0, 0(t0) # save addr to current address
    sd t1, 0(a0) # save current address to addr
_pm_page_free_end:
    ldra # restore return address
    ret

.section .data

current_address:
    .long 0x0000000000000000 # current address that is free
