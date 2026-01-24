.include "riscv.inc"
.include "vm.inc"

.section .text
.global walk

# walk through page table entries and return last page table entry translated from virtual address
walk: # a0 = ptbl (returns pte0 here), a1 = va, a2 = alloc; modified: t0, t1, t2, t3
    li t0, 2 # 3 levels of page table (from 2 to 1)
    li t1, 0 # page table entry address
_walk_loop:
    ptn t2, a1, t0 # load page index from virtual address
    push t1 # save affected registers
    li t1, 4
    mul t2, t2, t1 # multiply by size of page table entry size (uint64)
    pop t1 # restore registers
    add t2, t2, a0 # switch page table to that index
    ld t1, 0(t2) # load page table entry from page table
    btsti t3, t1, PTE_V # is page table entry available (exists)?
    beqz t3, _walk_alloc # if not, try to allocate
    pte2pa t1, t1 # convert page table entry to physical address of next page table entry
    mv a0, t1 # switch page table to next page table entry
_walk_loop_continue:
    dec t0 # go one page level down
    bgez t0, _walk_loop # loop until page level 1
_walk_end:
    ptni t2, a1, 0 # load zero page index from virtual address
    add t2, t2, a0 # switch page table to that index
    mv a0, t2 # return level 0 page table entry address
    ret
_walk_alloc:
    beqz a2, _walk_error # if alloc flag not set, trip
    push a0 # save affected registers
    call kalloc # allocate memory for page table entry
    mv t1, a0 # set page table entry address to allocated address
    pop a0 # restore registers
    push t0 # save affected registers
    push t3
    clr t0
    bseti t0, PTE_V # mark page table entry as available (exist)
    pa2pte t3, a0 # convert physical address of page table to page table entry
    or t0, t3, t0 # append converted address to page table entry
    sd t0, 0(t1) # store prebaked page table entry to page table entry address
    pop t0 # restore registers
    pop t3
    j _walk_loop_continue # continue loop
_walk_error:
    la a0, nonexistent_page_msg
    callr panic # walk error, should not return
    j . # if returned, halt

# translate virtual address into physical address
walk_addr: # a0 = pgtbl (returns pa here), a1 = va; modified: t0, t1, t2, t3
    push a1 # save original argument registers
    push a2
    clr a2
    callr walk # get last page table entry address from page table and virtual address
    ld a0, 0(a0) # load page table entry from page table entry address
    pte2pa a0, a0 # convert last page table entry inro physical address
    li t0, PAGE_SIZE
    and a1, a1, t0 # get first 12 bits of virtual address (offset to physical address)
    or a0, a0, a1 # combine physical address and offset together
    pop a2 # restore original argument registers
    pop a1
    ret

.section .data

nonexistent_page_msg:
    .asciz "walk: page does not exist!\n"