.include "riscv.inc"
.include "vm.inc"


.section .trampoline
.global utrap_vector
.global user_trapframe
.global user_switch

# Trap vector (user mode)
utrap_vector: # no arguments; modified: t0, t1, sepc
    csrw sscratch, a0
_utrap_vector_stackframe_create:
    la a0, user_trapframe
    sd x0,  0(a0) # store x0-x31 registers in stackframe
    sd x1,  8(a0)
    sd x2,  16(a0)
    sd x3,  24(a0)
    sd x4,  32(a0)
    sd x5,  40(a0)
    sd x6,  48(a0)
    sd x7,  56(a0)
    sd x8,  64(a0)
    sd x9,  72(a0)
    # store a0 last
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

    csrr t0, scause
    sd t0,  256(a0) # store suprevisor exception program counter
    csrr t0, sstatus
    sd t0,  264(a0) # store supervisor status
    csrr t0, sepc
    sd t0,  272(a0) # store supervisor cause
    csrr t0, satp
    sd t0,  280(a0) # store supervisor atp
    ld t0,  288(a0) # load supervisor kernel atp
    csrw satp, t0 # switch to kernel page table
    ld sp,  304(a0) # load kernel stack pointer

    csrr t0, sscratch
    sd t0, 80(a0) # now we can store a0
    csrw sscratch, a0

    call utrap_handler # call primary trap handler
_utrap_vector_stackframe_restore:
    csrr a0, sscratch
    ld t0,  280(a0)
    csrw satp, t0 # restore supervisor atp
    ld t0,  272(a0)
    csrw sepc, t0 # restore supervisor exception program counter
    ld t0,  264(a0)
    csrw sstatus, t0 # restore supervisor status
    ld t0,  256(a0)
    csrw scause, t0 # restore supervisor cause

    ld x31, 248(a0) # restore x1-x31 registers from stackframe
    ld x30, 240(a0)
    ld x29, 232(a0)
    ld x28, 224(a0)
    ld x27, 216(a0)
    ld x26, 208(a0)
    ld x25, 200(a0)
    ld x24, 192(a0)
    ld x23, 184(a0)
    ld x22, 176(a0)
    ld x21, 168(a0)
    ld x20, 160(a0)
    ld x19, 152(a0)
    ld x18, 144(a0)
    ld x17, 136(a0)
    ld x16, 128(a0)
    ld x15, 120(a0)
    ld x14, 112(a0)
    ld x13, 104(a0)
    ld x12, 96(a0)
    ld x11, 88(a0)
    # restore a0 last
    ld x9,  72(a0)
    ld x8,  64(a0)
    ld x7,  56(a0)
    ld x6,  48(a0)
    ld x5,  40(a0)
    ld x4,  32(a0)
    ld x3,  24(a0)
    ld x2,  16(a0)
    ld x1,  8(a0)
    # do not restore x0 because it's always zero

    ld x10, 80(a0) # now we can restore a0

    sret # return from trap vector

# User trap handler
utrap_handler: # a0 = stackframe address; modified: t0, t1, t2, t3
    svra # save return address
    ld t0, 296(a0) # load kernel trap vector address
    csrw stvec, t0 # write kernel trap vector address to supervisor trap vector to redirect supervisor traps to kernel mode handler
    li t0, 0x8000000000000000 # interrupt bit mask (bit 63 for rv64)
    ld t1, 256(a0) # load suprevisor status
    and t0, t1, t0 # mask interrupt bit
    bnez t0, _utrap_handler_interrupt # if interrupt bit set, handle interrupt, else handle exception
_utrap_handler_exception:
    li t0, SCAUSE_EXC_USER_ECALL
    beq t0, t1, _utrap_handler_uecall
    mv a1, t1
    call utrap_panic # if exception is unhandled, panic
_utrap_handler_uecall:
    call user_syscall_handler # call system call handler to handle system call
    ld t0, 272(a0) # read supervisor exception program counter
    addi t0, t0, 4 # adjust supervisor exception program counter to next instruction
    sd t0, 272(a0) # write modified supervisor exception program counter back
    j _utrap_handler_end
_utrap_handler_end:
    la t0, utrap_vector # load user trap vector address
    csrw stvec, t0 # write user trap vector address to supervisor trap vector to redirect user traps to user mode handler
    ldra # restore return address
    ret
_utrap_handler_interrupt:
    li t0, 0x7FFFFFFFFFFFFFFF # interrupt reason mask (bits 0-62 for rv64)
    and t1, t1, t0 # mask interrupt reason
    li t0, SCAUSE_INT_TIMER
    beq t0, t1, _utrap_handler_timer # if interrupt reason is timer, call timer handler
    call utrap_panic # unexpected interrupt, panic
_utrap_handler_timer:
    call timer_handler # call timer handler
    j _utrap_handler_end # return from trap handler

# User trap panic
utrap_panic: # a0 = stackframe address, a1 = exception code; modified: t0, a0, a1, a2
    la a0, trap_exception_msgs # load address of trap exception message address table
    slli t0, a1, 3 # multiply index by 8 (uint64) to get offset to message address
    add a0, a0, t0 # add offset and address of trap exception message address table
    ld a0, 0(a0) # load actual address from trap exception message address table
    call printraw # notify about panic
    li a0, '\n'
    call putc # put newline
    call cpu_halt # halt processor

# Switch to user mode
user_switch: # a0 = user pgtbl, a1 = user stack, a2 = user pc; modified: t0, t1, t2, t3, t4, a0, a1, a2, a3, a4, a5, a6, a7
    # not saving return address, never return
    call cpu_disable_sirqs # disable irqs during transition to user mode
    la t0, utrap_vector # load user trap vector address
    csrw stvec, t0 # write user trap vector address to supervisor trap vector
    la t0, user_trapframe # load user trapframe address
    la t1, _sp_addr # load kernel stack pointer address
    sd t1, 304(t0) # store kernel stack for future use
    csrr t1, satp
    sd t1, 288(t0) # store kernel atp for future use
    mksatp a0, a0, MMU_MODE_SV39 # create Sv39 supervisor atp
    csrw satp, a0 # write supervisor atp
    sfence.vma # flush TLB entries
    mv sp, a1 # switch to user stack
    csrw sepc, a2 # set return program counter to user starting address
    li t0, 0x100
    csrc sstatus, t0 # clear SPP bit (bit 8) to return to user mode
    mv t0, zero # clear registers to prevent information leak
    mv t1, zero
    mv t2, zero
    mv t3, zero
    mv t4, zero
    mv a0, zero
    mv a1, zero
    mv a2, zero
    mv a3, zero
    mv a4, zero
    mv a5, zero
    mv a6, zero
    mv a7, zero
    sret # switch to user mode

user_trapframe:
    .fill 320, 8, 0

.section .bss

itoa_buffer:
    .fill 16, 1, 0

.section .rodata

trap_trip_msg:
    .asciz "user mode exception"

trap_uecall_exception_msg:
    .asciz "user system call exception\n"

trap_store_fault_exception_msg:
    .asciz "Store/AMO access fault"

trap_illegal_instruction_exception_msg:
    .asciz "Illegal instruction"

trap_exception_msgs:
    .quad trap_trip_msg # instruction address misaligned
    .quad trap_trip_msg # instruction access fault
    .quad trap_illegal_instruction_exception_msg # illegal instruction
    .quad trap_trip_msg # breakpoint
    .quad trap_trip_msg # load address misaligned
    .quad trap_trip_msg # load access fault
    .quad trap_trip_msg # store/AMO address misaligned
    .quad trap_store_fault_exception_msg # store/AMO access fault
    .quad trap_trip_msg # ecall from U-mode
    .quad trap_trip_msg # ecall from S-mode
    .quad trap_trip_msg # reserved
    .quad trap_trip_msg # reserved
    .quad trap_trip_msg # instruction page fault
    .quad trap_trip_msg # load page fault
    .quad trap_trip_msg # reserved
    .quad trap_trip_msg # store/AMO page fault
