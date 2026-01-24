.section .text
.global kmain

kmain:
    call kalloc_init
    call kalloc_init