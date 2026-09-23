.include "riscv.inc"
.include "syscall.inc"

.section .text
.global user_syscall_handler

# User system call handler
user_syscall_handler: # a0 = stackframe address; modified: t0, t1, t2, t3
    svra # save return address
    ld t0, 136(a0) # load system call number from stackframe
    la t1, user_syscall_table # load user system call table address
    slli t0, t0, 3 # multiply system call number by 8 (uint64) to get actual index in system call table
    add t1, t1, t0 # add user system call table address and system call number offset
    ld t1, 0(t1) # load actual address of system call function from system call table
    beqz t1, _user_syscall_handler_unknown_sys # if we got zero address, return
    jalr t1 # call that function
_user_syscall_handler_end:
    ldra # restore return address
    ret
_user_syscall_handler_unknown_sys:
    j _user_syscall_handler_end # do not handle it currently

.section .rodata

user_syscall_table:
    .quad 0x0000000000000000
    .quad sys_exit
