MEMORY
{
    RAM : ORIGIN = 0x80000000, LENGTH = 2K
}

ENTRY(main);

SECTIONS
{
    .text :
    {
        *(.text .text.*);
    } > RAM    
    
    .data :
    {
        *(.data .data.* .rodata .rodata.* .bss .bss.*);
    } > RAM
}
