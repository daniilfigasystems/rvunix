ENTRY(_kentry);

SECTIONS
{
    . = 0x80000000;

    .text : ALIGN(4K)
    {
        PROVIDE(_text_start = .);
        build/boot.o(.text);
        *(.text);
        PROVIDE(_text_end = .);
    }

    .data : ALIGN(4K)
    {
        PROVIDE(_data_start = .);
        *(.data);
        *(.rodata);
        PROVIDE(_data_end = .);
    }

    .bss : ALIGN(4K)
    {
        PROVIDE(_bss_start = .);
        . += 0x1000;
        PROVIDE(_sp_addr = .);
        . += 0x1000;
        PROVIDE(_gp_addr = .);
        . += 0x1000;
        *(.bss);
        PROVIDE(_bss_end = .);
    }

    PROVIDE(_kern_end = .);
}