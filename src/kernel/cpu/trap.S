.include "riscv.inc"

.section .text
.extern user_trapframe
.global trap_init
.global trap_panic

# Initialize traps
trap_init: # no arguments; modified: t0, t1, stvec
    la t0, trap_vector
    la t1, user_trapframe
    sd t0, 296(t1) # store kernel trap vector address to stackframe
    csrw stvec, t0 # install trap vector in stvec (supervisor trap vector)
    callr cpu_enable_sirqs # enable supervisor interrupts
    ret

# Trap vector (kernel mode)
trap_vector: # no arguments; modified: t0, t1, sepc
_trap_vector_stackframe_create:
    addi sp, sp, -280 # preserve space for stackframe
    sd x0,  0(sp) # store x0-x31 registers in stackframe
    sd x1,  8(sp)
    sd x2,  16(sp)
    sd x3,  24(sp)
    sd x4,  32(sp)
    sd x5,  40(sp)
    sd x6,  48(sp)
    sd x7,  56(sp)
    sd x8,  64(sp)
    sd x9,  72(sp)
    sd x10, 80(sp)
    sd x11, 88(sp)
    sd x12, 96(sp)
    sd x13, 104(sp)
    sd x14, 112(sp)
    sd x15, 120(sp)
    sd x16, 128(sp)
    sd x17, 136(sp)
    sd x18, 144(sp)
    sd x19, 152(sp)
    sd x20, 160(sp)
    sd x21, 168(sp)
    sd x22, 176(sp)
    sd x23, 184(sp)
    sd x24, 192(sp)
    sd x25, 200(sp)
    sd x26, 208(sp)
    sd x27, 216(sp)
    sd x28, 224(sp)
    sd x29, 232(sp)
    sd x30, 240(sp)
    sd x31, 248(sp)

    csrr t0, scause
    sd t0,  256(sp) # store suprevisor exception program counter
    csrr t0, sstatus
    sd t0,  264(sp) # store supervisor status
    csrr t0, sepc
    sd t0,  272(sp) # store supervisor cause

    addi t0, sp, 280 # calculate original stack pointer
    sd t0, 16(sp) # store calculated original stack pointer

    mv a0, sp # pass stackframe address as argument
    call trap_handler # call primary trap handler

    li t0, 9 # scause code for supervisor ecall
    csrr t1, scause # read scause register
    beq t0, t1, _trap_vector_secall # if cause of exception was supervisor ecall, adjust program counter to next instruction
_trap_vector_stackframe_restore:
    # do not restore supervisor atp when returning to supervisor
    ld t0,  272(sp)
    csrw sepc, t0 # restore supervisor exception program counter
    ld t0,  264(sp)
    csrw sstatus, t0 # restore supervisor status
    ld t0,  256(sp)
    csrw scause, t0 # restore supervisor cause

    ld x31, 248(sp) # restore x1-x31 registers from stackframe
    ld x30, 240(sp)
    ld x29, 232(sp)
    ld x28, 224(sp)
    ld x27, 216(sp)
    ld x26, 208(sp)
    ld x25, 200(sp)
    ld x24, 192(sp)
    ld x23, 184(sp)
    ld x22, 176(sp)
    ld x21, 168(sp)
    ld x20, 160(sp)
    ld x19, 152(sp)
    ld x18, 144(sp)
    ld x17, 136(sp)
    ld x16, 128(sp)
    ld x15, 120(sp)
    ld x14, 112(sp)
    ld x13, 104(sp)
    ld x12, 96(sp)
    ld x11, 88(sp)
    ld x10, 80(sp)
    ld x9,  72(sp)
    ld x8,  64(sp)
    ld x7,  56(sp)
    ld x6,  48(sp)
    ld x5,  40(sp)
    ld x4,  32(sp)
    ld x3,  24(sp)
    # restore stack pointer last
    ld x1,  8(sp)
    # do not restore x0 because it's always zero

    ld x2,  16(sp) # now we can restore stack pointer

    sret # return from trap vector
_trap_vector_secall:
    ld t0, 272(a0) # read supervisor exception program counter
    nextinst t0 # adjust supervisor exception program counter to next instruction
    sd t0, 272(a0) # write modified supervisor exception program counter back
    j _trap_vector_stackframe_restore # continue restoring stackframe

# Trap handler
trap_handler: # a0 = stackframe address; modified: t0, t1, t2, t3
    svra # save return address
    li t0, 0x8000000000000000 # interrupt bit mask (bit 63 for rv64)
    ld t1, 256(a0) # load suprevisor status
    and t0, t1, t0 # mask interrupt bit
    bnez t0, _trap_handler_interrupt # if interrupt bit set, handle interrupt, else handle exception
_trap_handler_exception:
    li t0, SCAUSE_EXC_SUPERVISOR_ECALL
    beq t0, t1, _trap_handler_secall # if supervisor ecall, handle it (should be handled by machine mode, use supervisor handler for compatibility)
    li t0, SCAUSE_EXC_STORE_FAULT
    beq t0, t1, _trap_handler_store_fault # if store fault, handle it
    call trap_panic # if exception is unhandled, panic
_trap_handler_secall:
    la a0, trap_secall_exception_msg
    call printraw # notify about supervisor system call
    j _trap_handler_end
_trap_handler_store_fault:
    la a0, trap_store_fault_exception_msg
    call printraw # notify about AMO/Store access fault
    csrr a0, stval # load store address
    la a1, itoa_buffer # convert integer to itoa buffer
    li a2, 16 # hexadecimal base
    call itoa # convert integer to ASCII string
    mv a0, a1
    call printraw # now print store address
    li a0, '\n'
    call putc # put newline
    call cpu_halt # halt processor
_trap_handler_end:
    ldra # restore return address
    ret
_trap_handler_interrupt:
    li t0, 0x7FFFFFFFFFFFFFFF # interrupt reason mask (bits 0-62 for rv64)
    and t1, t1, t0 # mask interrupt reason
    li t0, SCAUSE_INT_TIMER
    beq t0, t1, _trap_handler_timer # if interrupt reason is timer, call timer handler
    call trap_panic # unexpected interrupt, panic
_trap_handler_timer:
    call timer_handler # call timer handler
    j _trap_handler_end # return from trap handler

# Trap panic
trap_panic: # a0 = stackframe address; modified: t0, a0, a1, a2
    ld a0, 256(a0) # load supervisor cause
    la a1, itoa_buffer # convert integer to itoa buffer
    li a2, 16 # hexadecimal base
    call itoa # convert integer to ASCII string
    la a0, trap_trip_msg
    call printraw # print trap trip message
    mv a0, a1
    call printraw # now print supervisor cause
    li a0, '\n'
    call putc # put newline
    call cpu_halt # halt processor

.section .bss

itoa_buffer:
    .fill 16, 1, 0

.section .rodata

trap_trip_msg:
    .asciz "supervisor mode exception: 0x"

trap_secall_exception_msg:
    .asciz "supervisor system call exception\n"

trap_store_fault_exception_msg:
    .asciz "Store/AMO access fault, stval=0x"
