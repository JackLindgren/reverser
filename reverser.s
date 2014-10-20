	.data
sent:	.asciiz "Enter the string to reverse"
delim:	.asciiz "Enter the delimiter"
banner:.asciiz "Here are the original and reversed strings: "
nlstr:	.asciiz "\n"
	.align 2
	
	.text
	.globl main
main:
	addi $sp,$sp,-224
	sw $ra,220($sp)
	# 120 = sentence
	# 20  = working buffer
	# 16  = delimstr

# get the string from the user:
	la $a0,sent
	la $a1,120($sp)	# store to stack
	li $a2,100	# limit
	jal InputDialogString

# copy the string
	la $a0,20($sp)	# location of buffer to copy to
	la $a1,120($sp) # location of sentence to copy
	jal strcpy	# copy the input string to working buffer

# get the delim from the user:
	la $a0,delim
	la $a1,16($sp)	# store to stack
	li $a2,4
	jal InputDialogString
	
# delimstr[1] = 0
	sb $zero,17($sp)# set second char of delimstr to 0

# reverse the string:
	la $a0,120($sp)	# location of the sentence
	la $a1,16($sp)	# location of the delim
	jal revwords

# $s0 = pointer to reversed string:
	move $s0,$v0	# reversed
	la $a0,20($sp)	# buffer
	jal strlen	# get length of buffer
	move $s1,$v0	# store length of buffer to $v1/nb
	move $a0,$s0	# reversed
	jal strlen	# get length of reversed
	add $s1,$s1,$v0	# $s1/nb = strlen(reversed) + strlen(buffer)
	addi $s1,$s1,2	# + newline + 1
	move $a0,$s1
	jal sbrk
	move $s1,$v0	# $s1 = sbrk(nb) (aka opstring)
# copy buffer to opstring:
	move $a0,$s1
	la $a1,20($sp)
	jal strcpy
# cat the newline onto the opstring:
	move $a0,$s1
	la $a1,nlstr
	jal strcat
# cat the reversed string onto the opstring:
	move $a0,$s1
	move $a1,$s0
	jal strcat
# display them both:
	la $a0,banner
	move $a1,$s1
	jal MessageDialogString
# clean up and exit:		
	lw $ra,220($sp)
	addi $sp,$sp,224
	jr $ra
	
	.globl revwords
revwords:
	addi $sp,$sp,-40
	sw $a0,36($sp)	# curword
	sw $a1,32($sp)	# delimstr
			# 28 reversed
			# 24 nextword
			# 20 nextdelim
	sw $ra,16($sp)
	
	li $a0,4	# get an empty word on heap
	jal sbrk	#
	sw $zero,0($v0)	# save NULL to the empty word
	sw $v0,28($sp)	# save pointer to NULL at reversed
		
revloop:
	lw $t1,36($sp)	# is curword empty? (is the word itself empty, not what it points to)
	beq $t1,$zero,revdone	# if curword == null, we're done
	lw $a0,36($sp)	# $a0 = curword
	lw $t0,32($sp)	# address of delimstr
	lb $a1,0($t0)	# load first byte of delimstr
	jal index	# get index of delimiter
	sw $v0,20($sp)	# store to nextdelim
	bne $v0,$zero,revelse # if nextdelim == null:
	sw $zero,24($sp)# nextword = NULL
	b rnxt
revelse:
	lw $v0,20($sp)

	lw $t0,36($sp)	# address of curword
	add $t0,$t0,$v0	# curword + offset for delim
	sb $zero,0($t0)	# *nextdelim = 0
	addi $t0,$t0,1	# nextdelim + 1
	sw $t0,24($sp)	# nextword = nextdelim + 1
rnxt:
	lw $a0,28($sp)	# reversed
	lw $a1,36($sp)	# curword
	lw $a2,32($sp)	# delimstr
	jal addword
	sw $v0,28($sp)	# reversed = addword(reversed,curword,delimstr)
	
	lw $t0,24($sp)	# nextword
	sw $t0,36($sp)	# curword = nextword
	b revloop
revdone:
	lw $v0,28($sp)
	lw $ra,16($sp)
	addi $sp,$sp,40
	jr $ra
	
	.globl addword
addword:
	addi $sp,$sp,-44
	sw $a0,40($sp)	# sentence
	sw $a1,36($sp)	# word
	sw $a2,32($sp)	# delimstr
	#	28	sentencelen
	#	24	wordlen
	#	20	newstr
	sw $ra,16($sp)	# ra
# sentencelen = 0
	sw $zero,28($sp)
# wordlen = strlen(word)
	lw $a0,36($sp)	# word
	jal strlen
	sw $v0,24($sp)	# store wordlen
# get the value of sentence to check if it's null
	lw $t0,40($sp)
	lw $t1,0($t0)
	beq $t1,$zero,nxt
	lw $a0,40($sp)
	jal strlen
	sw $v0,28($sp)
nxt:
	lw $t0,24($sp)
	lw $t1,28($sp)
	add $a0,$t0,$t1	# wordlen + sentencelen
	addi $a0,$a0,2	# + 2
	jal sbrk
	sw $v0,20($sp)	# location where we'll save our new string
	
	lw $a0,20($sp)	# location to copy to
	lw $a1,36($sp)	# word to copy over
	jal strcpy
# if sentence != NULL
	lw $t0,40($sp)
	lw $t1,0($t0)
	beq $t1,$zero,awdone
# strcpy (newstr + wordlen, delimstr)
	lw $t0,20($sp)
	lw $t1,24($sp)
	add $a0,$t0,$t1
	lw $a1,32($sp)
	jal strcpy
# strcpy (newstr + wordlen + 1, sentence)
	lw $t0,20($sp)
	lw $t1,24($sp)
	add $a0,$t0,$t1
	addi $a0,$a0,1
	lw $a1,40($sp)
	jal strcpy
awdone:
	lw $v0,20($sp)
	lw $ra,16($sp)
	addi $sp,$sp,44
	jr $ra
	
	.globl index
index:
	add $v0,$zero,$zero	# $v0 = 0 by default
idxloop:lb $t0,0($a0)
	beq $t0,$zero,itsnull
	beq $t0,$a1,idxdone	# if char isn't in the string, use default $v0
	addi $a0,$a0,1		# next character in string
	addi $v0,$v0,1		# increment return value
	b idxloop
itsnull:
	add $v0,$zero,$zero
idxdone:
	jr $ra
	
	.globl strcat
strcat:
	move $v0,$a0
end_of_first:
	lb $t0,0($a0)		# c = *orig
	beq $t0,$zero,sccopy	# c == 0 ?
	addi $a0,$a0,1		# orig++
	b end_of_first
sccopy:
	lb $t1,0($a1)
	beq $t1,$zero,scdone
	sb $t1,0($a0)
	addi $a0,$a0,1
	addi $a1,$a1,1
	b sccopy
scdone:
	sb $zero,0($a0)
	jr $ra
	
.include "util.s"
	
