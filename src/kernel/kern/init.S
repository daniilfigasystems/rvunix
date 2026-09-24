.include "riscv.inc"
.include "vm.inc"

.section .text
.extern utrap_vector
.global kmain

kmain:
    call kalloc_init
    la a0, init_vm_msg
    call uart_writestring
    call vm_init
    la a0, init_trap_msg
    call uart_writestring
    call trap_init
    la a0, init_timer_msg
    call uart_writestring
    li a0, 100
    call timer_init
_kmain_loop:
    la a0, init_completed_msg
    call uart_writestring
    li a0, 75000
    call timer_wait
    la a0, user_pagedir
    la a1, _trampoline_start
    mv a2, a1
    li a3, PTE_KERNEL_TEXT
    li a4, 1
    call map_pages
    push a0
    call kalloc
    mv a1, a0
    pop a0
    mv a2, a1
    li a3, PTE_USER_TEXT
    call map_pages
    push a0
    push a1
    push a2
    mv a0, a1
    la a1, init_user
    li a2, 32
    call memmove
    pop a2
    pop a1
    pop a0
    call user_switch
    call cpu_halt

.section .data

user_pagedir:
    .quad 0x0000000000000000 # user page directory address

.section .rodata

init_completed_msg:
    .asciz "init: initialization completed, switching to user mode\n"

init_vm_msg:
    .asciz "vm: initializing Virtual Memory\n"

init_trap_msg:
    .asciz "trap: initializing Trap Vector\n"

init_timer_msg:
    .asciz "timer: initializing Timer\n"

init_user:
    li a7, 1 # exit system call
    li a0, 2 # 2 = test return value
    ecall # do system call
