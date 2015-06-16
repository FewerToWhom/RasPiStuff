.section .text
.globl memcpy
// copies num elements from source pointer to dest pointer
// C signature: void memcpy(void* dest, const void* source, size_t num);
.func memcpy
memcpy:
	dst .req r0
	src .req r1
	num .req r2
	tmp .req r3

	push {r4}

	cmp num, #0
	beq stop$						// exits if num == 0
	cmp num, #4						// if less than 4 bytes to copy don't check for alignment and copies bytes
	movlt r4, num
	movlt num, #0					// ensures code will stop after byteLoop
	blt byteLoop$

	and tmp, dst, #3				// checks if the destination pointer is word aligned
	and r4, src, #3					// checks if the source pointer is word aligned
	teq r3, r4
	movne r4, num					// if they are not even mutually aligned, do byte copies all the way
	movne num, #0					// ensures code will stop after byteLoop
	bne byteLoop$


	cmp r4, #0						// they are mutually aligned -> check for word alignment
	rsbne r4, #4					// r4 = number of bytes until word alignment
	bne byteLoop$

aligned$:
	teq num, #0
	beq stop$
									// now both addresses are word aligned
	movs r4, num, lsr #5			// r4 <- num / 32, and checks if num > 32
	beq wordCopy$					// if not, try word copies

	push {r5-r12}

octoWord$:
	ldm src!, {r5-r12}				// reads 32 bytes (8 word) and increments src by 8 words
	stm dst!, {r5-r12}				// stores 32 bytes (8 word) and increments dst by 8 words
	subs r4, #1						// decrements number of 8 words
	bne octoWord$					// loops until no 8-word packet left to copy
	pop {r5-r12}

wordCopy$:
	ands num, num, #31				// subtracts number of 8-word blocks copied
	beq stop$						// exits if there is nothing else to copy
	movs r4, num, lsr #2			// r4 <- num / 4, and checks if num > 4
	beq byteCopy$					// if not, do byte copies

wordLoop$:
	ldr tmp, [src], #4				// reads 4 bytes (1 word) and increments src by 1 word
	str tmp, [dst], #4				// stores 4 bytes (1 word) and increments dst by 1 word
	subs r4, #1						// decrements number of words
	bne wordLoop$					// loops until no word packet left to copy

byteCopy$:
	ands num, num, #3				// subtracts number of words copied
	beq stop$						// exits if there is nothing else to copy
	mov r4, num
	mov num, #0

byteLoop$:
	ldrb tmp, [src], #1				// reads 1 byte from [src] into tmp
	strb tmp, [dst], #1				// writes 1 byte from tmp into [dst]
	subs r4, #1						// decrement number of bytes
	bne byteLoop$					// loops until no bytes left to copy
	b aligned$

stop$:
	pop {r4}
	.unreq tmp
	.unreq src
	.unreq dst
	.unreq num

	bx lr
.endfunc
