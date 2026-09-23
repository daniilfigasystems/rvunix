ENTRY(_kentry);

SECTIONS
{
    . = 0x80000000;

    .text : ALIGN(4K)
    {
        PROVIDE(_text_start = .);
        build/boot.o(.text);
        *(.text);
        . = ALIGN(4K);
        PROVIDE(_trampoline_start = .);
        *(.trampoline);
        PROVIDE(_text_end = .);
    }

    .rodata : ALIGN(4K)
    {
        *(.rodata);
        PROVIDE(_rodata_end = .); 
    }

    .data : ALIGN(4K)
    {
        PROVIDE(_data_start = .);
        . = ALIGN(8);
        *(.data .data.*);
        PROVIDE(_data_end = .);
    }

    PROVIDE(_gp_addr = _data_start + 0x800);

    .bss : ALIGN(4K)
    {
        PROVIDE(_bss_start = .);
        . += 0x1000;
        PROVIDE(_sp_addr = .);
        . += 0x1000;
        . = ALIGN(8);
        *(.bss .bss.*);
        . = ALIGN(4K);
        PROVIDE(_bss_end = .);
    }

    . = ALIGN(4K);
    PROVIDE(_kern_end = .);
}