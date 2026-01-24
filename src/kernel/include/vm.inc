# virtual address to bits
# Reserved [63:39]
# VPN[2] [38:30] index for root page table
# VPN[1] [29:21] index for level 1 page table
# VPN[0] [20:12] index for level 0 page table
# Page Offset [11:0] offset into the 4k physical page

.set PTE_V, 0x01
.set PTE_R, 0x02
.set PTE_W, 0x04
.set PTE_X, 0x08
.set PTE_U, 0x10
.set PTE_G, 0x20
.set PTE_A, 0x40
.set PTE_D, 0x80
.set PTE_V_BIT, 0
.set PTE_R_BIT, 1
.set PTE_W_BIT, 2
.set PTE_X_BIT, 3
.set PTE_U_BIT, 4
.set PTE_G_BIT, 5
.set PTE_A_BIT, 6
.set PTE_D_BIT, 7

# convert physical address to page table entry and store result in destination register
.macro pa2pte destreg, pa
    mv \destreg, \pa
    slli \destreg, \destreg, 12 # shift physical address by 12 (page size)
    srli \destreg, \destreg, 10 # shift physical address by 10 (permission bits)
.endm

# convert page table entry to physical address and store result in destination register
.macro pte2pa destreg, pte
    mv \destreg, \pte
    slli \destreg, \destreg, 10 # shift page table entry by 10 (permission bits)
    srli \destreg, \destreg, 12 # shift page table entry by 12 (page size)
.endm

# get index of page table entry from virtual address and page table level and store result in destination register (immediate)
.macro ptni destreg, va, level
    push t5
    push t6
    mv \destreg, \va
    li t6, 9
    li t5, \level
    mul t6, t6, t5 # calculate page table level
    addi t6, t6, 12 # page offset
    sll \destreg, \destreg, t6 # shift virtual address by 12 (page offset) plus 9 bits multiplied by page table level
    andi \destreg, \destreg, 0x1FF # filter 9 bits (page table index)
    pop t6
    pop t5
.endm

# get index of page table entry from virtual address and page table level and store result in destination register
.macro ptn destreg, va, level
    push t6
    mv \destreg, \va
    li t6, 9
    mul t6, t6, \level # calculate page table level
    addi t6, t6, 12 # page offset
    sll \destreg, \destreg, t6 # shift virtual address by 12 (page offset) plus 9 bits multiplied by page table level
    andi \destreg, \destreg, 0x1FF # filter 9 bits (page table index)
    pop t6
.endm