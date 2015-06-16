.section .text
.globl memset
// writes value to location pointer by ptr num times
// C signature: void * memset ( void * ptr, int value, size_t num );
// r1 is supposed to be cast to unsigned char
.func memset
memset:
	ptr .req r0
	val .req r1
	num .req r2

	cmp num, #0
	beq stop$						// exits if num == 0

	and val, val, #255				// ignores higher 3 bytes of val

//	rsbs r3, num, #4				// if less than 4 bytes to copy //- r3 <- 4 - num
	cmp num, #4
	movlt r3, num
	movlt num, #0					// ensures code will stop after byteLoop is over
	blt byteLoop$					// goes directly to byteLoop

	ands r3, ptr, #3				// if num >= 4 checks for alignment
	rsbne r3, r3, #4				// if not aligned, r3 < 4, r3 = number of bytes until word alignment
	subne num, r3					// subtract r3 from number of bytes to copy
	bne byteLoop$					// copy unaligned bytes

aligned$:
	teq num, #0
	beq stop$

	orr val, val, val, lsl #8
	orr val, val, val, lsl #16		// val contains 4 copies of the lowest original byte

	movs r3, num, lsr #5			// r3 <- num / 32, and checks if num > 32
	beq wordCopy$					// if not, try word copies

	push {r4-r11}
	mov r4, val					 	// if so, copy val to r5-r12 to make 8 word transfers
	mov r5, val
	mov r6, val
	mov r7, val
	mov r8, val
	mov r9, val
	mov r10, val
	mov r11, val

octoWord$:
	stm ptr!, {r4-r11}				// 32 bytes (8 word) copy and increments ptr by 8 words
	subs r3, #1						// decrements number of 8 words
	bne octoWord$					// loops until no 8-word packet left to copy
	pop {r4-r11}

wordCopy$:
	ands num, num, #31				// subtracts number of 8-word blocks copied
	beq stop$						// exits if there is nothing else to copy
	movs r3, num, lsr #2			// r3 <- num / 4, and checks if num > 4
	beq byteCopy$					// if not, do byte copies

wordLoop$:
	str val, [ptr], #4				// 4 byte (1 word) copy and increments ptr by 1 word
	subs r3, #1						// decrements number of words
	bne wordLoop$					// loops until no word packet left to copy

byteCopy$:
	ands num, num, #3				// subtracts number of words copied
	beq stop$						// exits if there is nothing else to copy
	mov r3, num
	mov num, #0

byteLoop$:
	strb val, [ptr], #1				// 1 byte copy and increments ptr by 1 byte
	subs r3, #1						// decrement number of bytes
	bne byteLoop$					// loops until no bytes left to copy
	b aligned$

stop$:
	.unreq ptr
	.unreq val
	.unreq num

	bx lr
.endfunc
