# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/kern/proc.S
#
# Description:
# Process management
#
# Author: Daniil Dunaeff (dan7)

.include "riscv.inc"
.include "proc.inc"
.include "vm.inc"
.include "memlayout.inc"
.include "limits.inc"
.include "errno.inc"

.section .text
.global proc_pid_allocate
.global proc_get_process
.global proc_create_process
.global proc_create_user_process
.global proc_thread_switch
.global proc_init

# Allocate process identifier
proc_pid_allocate: # no arguments; modified: t0, t1, a0 (returns allocated process identifier or an error)
    svra # save return address
    la t0, last_pid # load last process identifier address
    ld a0, 0(t0) # load last process identifier value from last process identifier
    li t1, MAX_PROC # load max process count immediate
    bge a0, t1, _proc_pid_allocate_err # if we hit process identifier count limit, return an error
    push a0 # save original last process identifier    
    inc a0 # increment last process identifier
    sd a0, 0(t0) # store modified last process identifier
    pop a0 # restore original last process identifier
_proc_pid_allocate_end:
    ldra # restore return address
    ret
_proc_pid_allocate_err:
    li a0, -EAGAIN # return EAGAIN error (resource temporarily unavailable)
    j _proc_pid_allocate_end # jump to end

# Get process structure from process identifier
proc_get_process: # a0 = pid; modified: t0, t1, a0 (returns address of process structure here)
    svra # save return address
    la t0, procs # load address of array of process structures
    li t1, 120 # process structure size
    mul t1, a0, t1 # multiply process identifier by process structure size to get process structure start
    add a0, t0, t1 # add base of process structures and offset to calculated processs structure
    ldra # restore return address
    ret

# Create new process
proc_create_process: # a0 = parent, a1 = name; modified: t0, t1, t2, a0 (returns process structure here)
    svra # save return address
    push a1 # save original argument registers
    push a2
    push a0 # save address of parent process structure for future use
    call proc_pid_allocate # allocate process identifier for new process
    bltz a0, _proc_create_process_err # if function returned an error, return an error
    push a0 # save process identifier for future use
    call proc_get_process # get address of process structure
    bltz a0, _proc_create_process_err # if function returned an error, return an error
    li a1, 0 # fill process structure with zeros
    li a2, 120 # process structure size
    call memset # zero out process structure
    li t0, PSTATE_USED # load used process state immediate
    sd t0, 8(a0) # mark process as used
    pop t0 # restore process identifier
    push a0 # save address of process structure for future use
    call pm_page_allocate # allocate page for context
    mv t1, a0 # transfer page address to temporary register
    pop a0 # restore address of process structure
    sd t1, 0(a0) # store address of process context
    li t1, 256 # kernel thread context size
    mul t1, t0, t1 # multiply process identifier by kernel thread context size to get offset to kernel thread context structure
    la t2, kctxs # load address of array of kernel thread context structures
    add t2, t2, t1 # add base of kernel thread context structures and offset to calculated kernel thread context structure
    sd t2, 80(a0) # store address of kernel thread context
    pop t0 # restore address of parent process structure
    sd t0, 48(a0) # assign parent process
    sd a2, 104(a0) # assign process name
    push a0 # save address of process structure
    call pm_page_allocate # allocate page for user page table
    mv t0, a0 # transfer page address to temporary register
    pop a0 # restore address of process structure
    sd t0, 72(a0) # store user page table address
_proc_create_process_end:
    pop a2 # restore original argument registers
    pop a1
    ldra # restore return address
    ret
_proc_create_process_err:
    li a0, -EAGAIN # return EAGAIN error (resource temporarily unavailable)
    j _proc_create_process_end # jump to end

# Create scheduler process
proc_create_sched_process: # no arguments; modified: t0, t1, t2
    svra # save return address
    push a0 # save original argument registers
    push a1
    li a0, 0 # no parent
    la a1, proc_sched_name # sched process name
    call proc_create_process # create new process
_proc_create_sched_process_end:
    pop a1 # restore original argument registers
    pop a0
    ldra # restore return address
    ret

# Create user process
proc_create_user_process: # a0 = parent, a1 = name, a2 = address of machine code (must be page aligned), a3 = size; modified: t0, t1, t2
    svra # save return address
    push a0 # save original argument registers
    push a1
    push a2
    push a3
    call proc_create_process # create process
    ld t0, 72(a0) # load address of user page table
    ld t1, 0(a0) # load address of user trapframe
    # push a0 # save address of process structure
    mv a0, t0 # transfer user page table address to first argument for vm_map_pages
    mv a1, t1 # transfer user trapframe address to second argument for vm_map_pages
    push a3 # save size of program for future use
    push a2 # save address of machine code for future use
    li a2, MM_TRAPFRAME # map user trapframe at high address
    li a3, 1 # map one page
    call vm_map_pages # map user trapframe
    la a1, _trampoline_start # load address of trampoline section start
    li a2, MM_TRAMPOLINE # map trampoline at high address
    li a3, 1 # map one page
    call vm_map_pages # map trampoline
    pop a1 # restore address of machine code
    li a2, 0x1000000 # default starting address of user program
    pop a3 # restore size of program
    call vm_map_size # map whole program
    push a0 # save address of user page table for future use
    call pm_page_allocate # allocate page for user stack
    mv a1, a0 # transfer user stack address to second argument for vm_map_size
    pop a0 # restore address of user page table
    add a2, a2, a3 # calculate last address of program
    li t0, 4096 # stack size
    add a2, a2, t0 # calculate stack address
    mv a3, t0 # transfer stack size to first argument for vm_map_size
    call vm_map_size # map stack
    li a3, 0x1000000 # entry point of the process
    call user_switch # switch to user mode
_proc_create_user_process_end:
    pop a3 # restore original argument registers
    pop a2
    pop a1
    pop a0
    ldra # restore return address
    ret

# Initialize process manager
proc_init: # no arguments; modified: t0, t1, t2, t3
    svra # save return address
    call proc_create_sched_process # create scheduler process
    ldra # restore return address
_proc_init_end:
    ret

# Switch kernel thread
proc_thread_switch: # a0 = current_ctx, a1 = ctx; modified: t0, t1, t2
    sd x0,  0(a0) # save x0-x31 registers
    sd x1,  8(a0)
    sd x2,  16(a0)
    sd x3,  24(a0)
    sd x4,  32(a0)
    sd x5,  40(a0)
    sd x6,  48(a0)
    sd x7,  56(a0)
    sd x8,  64(a0)
    sd x9,  72(a0)
    sd x10, 80(a0)
    sd x11, 88(a0)
    sd x12, 96(a0)
    sd x13, 104(a0)
    sd x14, 112(a0)
    sd x15, 120(a0)
    sd x16, 128(a0)
    sd x17, 136(a0)
    sd x18, 144(a0)
    sd x19, 152(a0)
    sd x20, 160(a0)
    sd x21, 168(a0)
    sd x22, 176(a0)
    sd x23, 184(a0)
    sd x24, 192(a0)
    sd x25, 200(a0)
    sd x26, 208(a0)
    sd x27, 216(a0)
    sd x28, 224(a0)
    sd x29, 232(a0)
    sd x30, 240(a0)
    sd x31, 248(a0)
    ld x31, 248(a1) # restore x0-x31 registers from context
    ld x30, 240(a1)
    ld x29, 232(a1)
    ld x28, 224(a1)
    ld x27, 216(a1)
    ld x26, 208(a1)
    ld x25, 200(a1)
    ld x24, 192(a1)
    ld x23, 184(a1)
    ld x22, 176(a1)
    ld x21, 168(a1)
    ld x20, 160(a1)
    ld x19, 152(a1)
    ld x18, 144(a1)
    ld x17, 136(a1)
    ld x16, 128(a1)
    ld x15, 120(a1)
    ld x14, 112(a1)
    ld x13, 104(a1)
    ld x12, 96(a1)
    ld x11, 88(a1)
    ld x10, 80(a1)
    ld x9,  72(a1)
    ld x8,  64(a1)
    ld x7,  56(a1)
    ld x6,  48(a1)
    ld x5,  40(a1)
    ld x4,  32(a1)
    ld x3,  24(a1)
    ld x2,  16(a1)
    ld x1,  8(a1)
    # do not restore x0 because it is always zero
_proc_thread_switch_end:
    ret # must return from point where context was saved

.section .rodata

proc_sched_name:
    .asciz "sched"

.section .bss

# ==============================================================================
# Kernel thread context (kctx) structure definition
# Total size: 256 bytes (assuming 8 byte (uint64) alignment for 64-bit registers)
# ==============================================================================
# Offset  | Size (B) | Register / Field description
# --------|----------|---------------------------------------------------------
# 0       | 8        | x0  (zero)  - always 0, stored but not restored
# 8       | 8        | x1  (ra)    - return address
# 16      | 8        | x2  (sp)    - user/previous stack pointer
# 24      | 8        | x3  (gp)    - global pointer
# 32      | 8        | x4  (tp)    - thread pointer
# 40      | 8        | x5  (t0)    - temporary 0
# 48      | 8        | x6  (t1)    - temporary 1
# 56      | 8        | x7  (t2)    - temporary 2
# 64      | 8        | x8  (s0/fp) - saved register 0 / frame pointer
# 72      | 8        | x9  (s1)    - saved register 1
# 80      | 8        | x10 (a0)    - argument 0 / return value (stored last via sscratch)
# 88      | 8        | x11 (a1)    - argument 1
# 96      | 8        | x12 (a2)    - argument 2
# 104     | 8        | x13 (a3)    - argument 3
# 112     | 8        | x14 (a4)    - argument 4
# 120     | 8        | x15 (a5)    - argument 5
# 128     | 8        | x16 (a6)    - argument 6
# 136     | 8        | x17 (a7)    - argument 7
# 144     | 8        | x18 (s2)    - saved register 2
# 152     | 8        | x19 (s3)    - saved register 3
# 160     | 8        | x20 (s4)    - saved register 4
# 168     | 8        | x21 (s5)    - saved register 5
# 176     | 8        | x22 (s6)    - saved register 6
# 184     | 8        | x23 (s7)    - saved register 7
# 192     | 8        | x24 (s8)    - saved register 8
# 200     | 8        | x25 (s9)    - saved register 9
# 208     | 8        | x26 (s10)   - saved register 10
# 216     | 8        | x27 (s11)   - saved register 11
# 224     | 8        | x28 (t3)    - temporary 3
# 232     | 8        | x29 (t4)    - temporary 4
# 240     | 8        | x30 (t5)    - temporary 5
# 248     | 8        | x31 (t6)    - temporary 6
# ==============================================================================
kctxs:
    .fill 256 * MAX_PROC, 1, 0

# ==============================================================================
# Process context (user trapframe) structure definition
# Total size: 320 bytes (assuming 8 byte (uint64) alignment for 64-bit registers)
# ==============================================================================
# Offset  | Size (B) | Register / Field description
# --------|----------|---------------------------------------------------------
# 0       | 8        | x0  (zero)  - always 0, stored but not restored
# 8       | 8        | x1  (ra)    - return address
# 16      | 8        | x2  (sp)    - user/previous stack pointer
# 24      | 8        | x3  (gp)    - global pointer
# 32      | 8        | x4  (tp)    - thread pointer
# 40      | 8        | x5  (t0)    - temporary 0
# 48      | 8        | x6  (t1)    - temporary 1
# 56      | 8        | x7  (t2)    - temporary 2
# 64      | 8        | x8  (s0/fp) - saved register 0 / frame pointer
# 72      | 8        | x9  (s1)    - saved register 1
# 80      | 8        | x10 (a0)    - argument 0 / return value (stored last via sscratch)
# 88      | 8        | x11 (a1)    - argument 1
# 96      | 8        | x12 (a2)    - argument 2
# 104     | 8        | x13 (a3)    - argument 3
# 112     | 8        | x14 (a4)    - argument 4
# 120     | 8        | x15 (a5)    - argument 5
# 128     | 8        | x16 (a6)    - argument 6
# 136     | 8        | x17 (a7)    - argument 7
# 144     | 8        | x18 (s2)    - saved register 2
# 152     | 8        | x19 (s3)    - saved register 3
# 160     | 8        | x20 (s4)    - saved register 4
# 168     | 8        | x21 (s5)    - saved register 5
# 176     | 8        | x22 (s6)    - saved register 6
# 184     | 8        | x23 (s7)    - saved register 7
# 192     | 8        | x24 (s8)    - saved register 8
# 200     | 8        | x25 (s9)    - saved register 9
# 208     | 8        | x26 (s10)   - saved register 10
# 216     | 8        | x27 (s11)   - saved register 11
# 224     | 8        | x28 (t3)    - temporary 3
# 232     | 8        | x29 (t4)    - temporary 4
# 240     | 8        | x30 (t5)    - temporary 5
# 248     | 8        | x31 (t6)    - temporary 6
# --------|----------|---------------------------------------------------------
# 256     | 8        | scause      - supervisor cause register
# 264     | 8        | sstatus     - supervisor status register
# 272     | 8        | sepc        - supervisor exception program counter
# 280     | 8        | satp        - supervisor user/previous page table register
# --------|----------|---------------------------------------------------------
# 288     | 8        | kernel_satp - kernel page table root pointer (read-only, stored only when switching to user mode)
# 296     | 8        | kernel_stvec- kernel supervisor trap vector (read-only, stored only when switching to user mode)
# 304     | 8        | kernel_sp   - kernel stack pointer (read-only, stored only when switching to user mode)
# --------|----------|---------------------------------------------------------
# 312     | 8        | proc        - address of process structure (reserved for now)
# ==============================================================================

# ==============================================================================
# Process structure definition
# Total size: 118 bytes (assuming 8 byte (uint64) alignment for RV64)
# ==============================================================================
# Offset  | Size (B) | Field description
# --------|----------|---------------------------------------------------------
# 0       | 8        | trapframe   - address of trapframe structure
# 8       | 8        | procstate   - process state
# 16      | 8        | chan        - channel (reserved for now)
# 24      | 8        | killed      - killed
# 32      | 8        | exstatus    - exit status
# 40      | 8        | pid         - process identifier
# 48      | 8        | parent      - address of parent process structure
# 56      | 8        | kstack      - virtual address of kernel stack
# 64      | 8        | size        - size of process memory (B)
# 72      | 8        | pgtable     - user page table
# 80      | 8        | kctx        - address of kernel context structure
# 88      | 8        | ofile       - address of array containing addresses of opened file structures
# 96      | 8        | cwd         - current directory
# 104     | 8        | name        - address of process name string
# 112     | 8        | mode        - current mode of process (0 for native, 1 for rvdos emulation) (reserved for now)
# ==============================================================================
sched_proc:
procs:
    .fill 120 * MAX_PROC, 1, 0

last_pid:
    .quad 0x0000000000000000 # last process identifier