.include "riscv.inc"

.section .text
.global memset
.global memmove
.global memcpy
.global strlen
.global strcpy
.global itoa

# Fill memory with value
memset: # a0 = dest, a1 = value, a2 = size; modified: t0
    svra # save return address
    push a0 # save original argument registers
    li t0, 0
_memset_loop:
    sb a1, 0(a0) # store value to destination address
    inc a0 # increment destination address
    inc t0 # increment counter
    bne t0, a2, _memset_loop # loop until counter is equal to size
_memset_end:
    pop a0 # restore original argument registers
    ldra # restore return address
    ret

# Move source size bytes to destination
memmove: # a0 = dest, a1 = src, a2 = size; modified: t0
    svra # save return address
    push a0 # save original argument registers
    push a1
    push a2
    beqz a2, _memmove_end # if size is zero, exit
    ble a0, a1, _memmove_decrement_check # if destination address is less than source address, start moving from end
_memmove_increment_loop:
    lb t0, 0(a1) # load value from source address
    sb t0, 0(a0) # store value to destination address
    inc a0 # increment destination address
    inc a1 # increment source address
    dec a2 # decrement count
    bnez a2, _memmove_increment_loop # loop until moved size bytes
    j _memmove_end # else exit
_memmove_decrement_check:
    add t0, a1, a2 # check for overlap
    bge t0, a0, _memmove_decrement # if overlap, do decrement
    j _memmove_increment_loop # else do increment
_memmove_decrement:
    add a0, a0, a2 # move destination address to end (dst + size)
    add a1, a1, a2 # move source address to end (src + size)
_memmove_decrement_loop:
    dec a0 # decrement destination address
    dec a1 # decrement source address
    lb t0, 0(a1) # load value from source address
    sb t0, 0(a0) # store value to destination address
    dec a2 # decrement count
    bnez a2, _memmove_decrement_loop # loop until moved size bytes
_memmove_end:
    pop a2 # restore original argument registers
    pop a1
    pop a0
    ldra # restore return address
    ret

# Copy source size bytes to destination
memcpy: # a0 = dest, a1 = src, a2 = size; modified: t0
    svra # save return address
    push a0 # save original argument registers
    li t0, 0
_memcpy_loop:
    push t0 # save temporary register to reduce registers use
    lb t0, 0(a1) # load value from source address
    sb t0, 0(a0) # store value to destination address
    pop t0 # restore temporary register
    inc a0 # increment destination address
    inc a1 # increment source address
    inc t0 # increment counter
    bne t0, a2, _memcpy_loop # loop until counter is equal to size
_memcpy_end:
    pop a0 # restore original argument registers
    ldra # restore return address
    ret

# Get string length
strlen: # a0 = string address; modified: t0, t1, a0 (returns string length here)
    # no need to save original argument registers, we will return length in a0 anyway
    svra # save return address
    li t0, 0 # string length counter
_strlen_loop:
    lb t1, 0(a0) # load value from string pointer
    beqz t1, _strlen_end # if value is equal to zero, it is string null terminator, exit from loop
    inc a0 # increment string pointer
    inc t0 # increment string length counter
    j _strlen_loop # loop until string end
_strlen_end:
    mv a0, t0 # return string length
    ldra # restore return address
    ret

# Copy source string to destination string buffer
strcpy:

# Convert integer to ASCII string
itoa: # a0 = value, a1 = dest, a2 = base; modified: t0, t1, t2
    svra # save return address
    push a0 # save original argument registers
    push a1
_itoa_loop:
    li t0, 10
    remu t1, a0, a2 # calculate remainder of value
    bge t1, t0, _itoa_hex # if value is bigger than 10, print as hex, else print as decimal integer
    addi t1, t1, '0' # convert to ASCII character
    j _itoa_continue
_itoa_hex:
    sub t1, t1, t0 # subtract 10 from digit to get hex ASCII index
    addi t1, t1, 'A' # convert to ASCII character (hex)
_itoa_continue:
    sb t1, 0(a1) # store ASCII character to destination buffer
    divu a0, a0, a2 # switch to next digit by division
    inc a1 # increment destination buffer address
    bnez a0, _itoa_loop # loop until parsed all digits
_itoa_reverse:
    sb zero, 0(a1) # store null terminator at string end
    dec a1 # do not reverse null terminator
    ld t0, 0(sp) # set destination buffer start pointer
_itoa_reverse_loop:
    bgeu t0, a1, _itoa_end # if destination buffer start pointer is equal to destination buffer end pointer, exit 
    lb t1, 0(t0) # load value from destination buffer start
    lb t2, 0(a1) # load value from destination buffer end
    sb t1, 0(a1) # store value from destination buffer start to destination buffer end
    sb t2, 0(t0) # store value from destination buffer end to destination buffer start
    inc t0 # increment destination buffer start pointer
    dec a1 # decrement destination buffer end pointer
    j _itoa_reverse_loop
_itoa_end:
    pop a1 # restore original argument registers
    pop a0
    ldra # restore return address
    ret
