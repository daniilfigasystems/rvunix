.set PAGE_SIZE, 4096 # risc-v typical page size is 4k

# push register
.macro push reg
    addi sp, sp, -8
    sd \reg, 0(sp)
.endm

# pop register
.macro pop reg
    ld \reg, 0(sp)
    addi sp, sp,8
.endm

# save return address
.macro svra
    push ra
.endm

# load return address
.macro ldra
    pop ra
.endm

# recursive call
.macro callr addr
    svra
    call \addr
    ldra
.endm

# increment register by 1
.macro inc reg
    addi \reg, \reg, 1
.endm

# decrement register by 1
.macro dec reg
    addi \reg, \reg, -1
.endm

# increment register by 4 (typically used by adjusting program counter to next instruction)
.macro nextinst reg
    addi \reg, \reg, 4
.endm

# swap values between registers reg1 and reg2
.macro swp reg1, reg2
    push \reg1
    mv \reg1, \reg2
    pop \reg2
.endm

# test bit n of register reg and place result in destination register destreg (immediate)
.macro btsti destreg, reg, n
    slli \destreg, \reg, \n
    andi \destreg, \destreg, 1
.endm

# test bit located in register nreg of register reg and place result in destination register destreg
.macro btst destreg, reg, nreg
    sll \destreg, \reg, \nreg
    andi \destreg, \destreg, 1
.endm

# set bit n of register reg (immediate)
.macro bseti reg, n
    push t6
    li t6, 1
    srli t6, t6, \n
    or \reg, \reg, t6
    pop t6
.endm

# set bit located in register nreg of register reg 
.macro bset reg, nreg
    push t6
    li t6, 1
    srl t6, t6, \nreg
    or \reg, \reg, t6
    pop t6
.endm

# clear bit n of register reg (immediate)
.macro bclri reg, n
    push t5
    li t6, 1
    srli t6, t6, \n
    push \reg
    li \reg, 0xFFFFFFFFFFFFFFFF
    xor t6, t6, \reg
    pop \reg
    and \reg, \reg, t6
    pop t6
.endm

# clear bit n located in register nreg of register reg
.macro bclr reg, nreg
    push t5
    li t6, 1
    srl t6, t6, \nreg
    push \reg
    li \reg, 0xFFFFFFFFFFFFFFFF
    xor t6, t6, \reg
    pop \reg
    and \reg, \reg, t6
    pop t6
.endm

# clear whole register reg
.macro clr reg
    xor \reg, \reg, \reg
.endm

# page align address
.macro pgalign addr
    push t6
    li t6, 0xFFFFFFFFFFFFF000
    and \addr, \addr, t6
    pop t6
.endm

# page align address up
.macro pgalignup addr
    push t6
    li t6, PAGE_SIZE
    addi t6, t6, -1
    add \addr, \addr, t6
    li t6, 0xFFFFFFFFFFFFF000
    and \addr, \addr, t6
    pop t6
.endm
