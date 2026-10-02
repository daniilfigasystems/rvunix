# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/kern/init.S
#
# Description:
# Kernel initialization
#
# Author: Daniil Dunaeff (dan7)

.include "riscv.inc"
.include "vm.inc"
.include "memlayout.inc"

.section .text
.extern utrap_vector
.global kmain

kmain:
    call pm_init
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
    call pm_page_allocate
    mv a2, a0
    li a3, 4096
    call proc_create_user_process
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
