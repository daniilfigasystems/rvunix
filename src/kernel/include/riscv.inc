# Definitions

.set PAGE_SIZE, 4096 # RISC-V typical page size is 4k
.set SCAUSE_INT_TIMER, 0x05 # RISC-V timer interrupt number is 5
.set SCAUSE_EXC_USER_ECALL, 0x08 # RISC-V user ecall number is 8
.set SCAUSE_EXC_SUPERVISOR_ECALL, 0x09 # RISC-V supervisor ecall number is 9
.set SCAUSE_EXC_STORE_FAULT, 0x0F # RISC-V Store/AMO access fault number is 15

# Functions

# Push register
.macro push reg
    addi sp, sp, -8
    sd \reg, 0(sp)
.endm

# Pop register
.macro pop reg
    ld \reg, 0(sp)
    addi sp, sp, 8
.endm

# Save return address
.macro svra
    push ra
.endm

# Load return address
.macro ldra
    pop ra
.endm

# Recursive call
.macro callr addr
    svra
    call \addr
    ldra
.endm

# Increment register by 1
.macro inc reg
    addi \reg, \reg, 1
.endm

# Decrement register by 1
.macro dec reg
    addi \reg, \reg, -1
.endm

# Adjust register to next instruction (typically used for adjusting program counter to next instruction)
.macro nextinst reg
    push t5
    push t6
    lhu t5, 0(\reg) # load instruction
    li t6, 3
    and t5, t5, t6 # filter instruction size bits
    beq t5, t6, .L_is_32bit # determine instruction size (11 (3) = 32 bit, else 16 bit)
.L_is_16bit: # it is an compressed instruction
    addi \reg, \reg, 2 # adjust program counter by 2
    j .L_nextinst_end
.L_is_32bit: # it is an regular instruction
    addi \reg, \reg, 4 # adjust program counter by 4
.L_nextinst_end:
    pop t6
    pop t5
.endm

# Swap values between registers reg1 and reg2
.macro swp reg1, reg2
    push \reg1
    mv \reg1, \reg2
    pop \reg2
.endm

# Test bit n of register reg and place result in destination register destreg (immediate)
.macro btsti destreg, reg, n
    srli \destreg, \reg, \n
    andi \destreg, \destreg, 1
.endm

# Test bit located in register nreg of register reg and place result in destination register destreg
.macro btst destreg, reg, nreg
    srl \destreg, \reg, \nreg
    andi \destreg, \destreg, 1
.endm

# Set bit n of register reg (immediate)
.macro bseti reg, n
    push t6
    li t6, 1
    slli t6, t6, \n
    or \reg, \reg, t6
    pop t6
.endm

# Set bit located in register nreg of register reg 
.macro bset reg, nreg
    push t6
    li t6, 1
    sll t6, t6, \nreg
    or \reg, \reg, t6
    pop t6
.endm

# Clear bit n of register reg (immediate)
.macro bclri reg, n
    push t6
    li t6, 1
    srli t6, t6, \n
    push \reg
    li \reg, 0xFFFFFFFFFFFFFFFF
    xor t6, t6, \reg
    pop \reg
    and \reg, \reg, t6
    pop t6
.endm

# Clear bit n located in register nreg of register reg
.macro bclr reg, nreg
    push t6
    li t6, 1
    srl t6, t6, \nreg
    push \reg
    li \reg, 0xFFFFFFFFFFFFFFFF
    xor t6, t6, \reg
    pop \reg
    and \reg, \reg, t6
    pop t6
.endm

# Clear whole register reg
.macro clr reg
    xor \reg, \reg, \reg
.endm

# Page align address
.macro pgalign reg, addr
    push t6
    li t6, 0xFFFFFFFFFFFFF000
    and \reg, \addr, t6
    pop t6
.endm

# Page align address up
.macro pgalignup reg, addr
    push t6
    li t6, PAGE_SIZE
    addi t6, t6, -1
    add \reg, \addr, t6
    li t6, 0xFFFFFFFFFFFFF000
    and \reg, \reg, t6
    pop t6
.endm
