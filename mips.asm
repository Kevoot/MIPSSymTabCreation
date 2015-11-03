		          .data
inArr:		    .word		  0:100
symTab:		    .word		  0:100
string:		    .asciiz		"\nPlease enter the new tokens and type: "
string2:	    .asciiz		"\nSymtab contents:\n"
formatLabel:	.asciiz		"\nLabel: "
formatAddr:	  .asciiz		"\nAt address: 0x"
formatType:	  .asciiz		"\nOf type: "
LOC:		      .word		0
saveReg: 	    .word 0:3


		          .text
main:		      li	$t0, 0x400		#initialize LOC to starting address
		          sw 	$t0, LOC		
	  	        la	$t1, inArr		#load address of inArr and symtab
		          la	$t9, symTab
		
input:		    la 	$a0, string		#ask user for input
		          li 	$v0, 4
		          syscall
		
		          la 	$a0, ($t1)		#get input
		          li	$a1, 10
		          li	$v0, 8
		          syscall
		
		          lb	$t4, ($a0)		#load first byte of input string
		          beq	$t4, 0x23, inputEnd	#If # symbol is found, time to check all of inArr for variables and labels
		          addi	$t1, $t1, 12		#Otherwise, add 12 to the address and continue taking input
		          j	input			
		
inputEnd:		  la	$a0, inArr		#set the index of the input back to the first element and begin checking
		          j 	checkVar
				
checkVar:     lw	$t5, ($a0)		#use 3 temp register to analyze each input token
		          lw	$t6, 4($a0)
		          lw	$t7, 8($a0)
		          lb	$t8, ($a0)		#use $t8 to detect "," or ":"
		          beq	$t8, 0x23, beginPrint	#branches to print if # symbol detected
		          beq	$t8, 0x2c, operator	#Check to see if next character is ","
		          bne	$t7, 0x32, noVar	#Check to see if the 3rd byte indicates type 2
		          j	isVar			#else do further checks to see if it is actually a label or variable

noVar:        addi	$a0, $a0, 12		#if no label or variable found, then increment to next entry
	          	j	checkVar
		
isVar:		    li	$t2, 0x3a		#Check to see if the next is a colon, if it is, then it must be a label
		          lb	$t3, 12($a0)		#the next value (could be colon)
		          jal	setLabel
		          beq	$t2, $t3, addtoSymTab
		          addi	$a0, $a0, 12
		          j	checkVar
		
setLabel:	    li	$t7, 0x00000031		#Sets to Label status to ASCI "1" for true
		          jr	$ra		
				
operator:     lb	$t5, 20($a0)		#load next entry type
		          bne	$t5, 0x32, noVar	#if the next entry isn't of type 2, then it isn't a label or variable
              addi	$a0, $a0, 12		#if a current entry is comma, and next is of type 2, then it is a variable
	            lb	$t2, 8($a0)		
		          lw	$t5, ($a0)
		          lw	$t6, 4($a0)
		          li	$t7, 0x00000030		#Sets to Label status "0" for false
		          beq	$t2, 0x32, addtoSymTab	#if next byte is a type 2, it is a label
		          b 	checkVar		#otherwise skip to the next token

addtoSymTab:  sw	$t5, ($t9)		#store 1 word at a time to make formatting easier in the end
		          sw	$t6, 4($t9)
		          li	$t4, 0x00000000		#Store a null word for padding in formatting
		          sw	$t4, 8($t9)
		          sw	$t7, 12($t9)		#location of type
		          sw	$t4, 16($t9)		#Again, padding for formatting
		          move	$t4, $a0		#temp store a0 address
		          lw	$a0, LOC
		          jal	hex2char		#convert LOC to hex characters
		          sw	$t0, LOC		#store new value of LOC back in variable
		          move 	$a0, $t4		#set a0 back to it's original address
		          sw	$v0, 20($t9)		#store LOC in symtab
		          li	$t4, 0x00000000		#padding...again
		          sw	$t4, 24($t9)		
		          addi	$a0, $a0, 12		#go to next index inArr
		          addi	$t9, $t9, 28		#increment to next spot in symtab
		          lb	$t2, ($a0)		#check to see if next character is "#"
		          beq	$t2, 0x23, beginPrint	#if it is, then time to print everything out
		          b	checkVar		
		
beginPrint:	  la	$t9, symTab		#Prints header of the printout
		          la	$a0, string2	
		          li	$v0, 4
		          syscall

printSymTab:					  #overly complicated since I wanted the formatting to look good
		          la	$a0, formatLabel
		          li 	$v0, 4
		          syscall
		
		          la	$a0, ($t9)		#print label/variable
		          li	$v0, 4
		          syscall
		
		          la	$a0, formatType		
		          li	$v0, 4
		          syscall
		
		          la	$a0, 12($t9)		#print type
		          li	$v0, 4
		          syscall

		          la	$a0, formatAddr
		          li	$v0, 4
		          syscall
		
		          la	$a0, 20($t9)		#print address
		          li	$v0, 4
		          syscall

		
		          addi	$t9, $t9, 28		#increment to next entry in symtab
		          lb	$t2, ($t9)
		          beq	$zero, $t2, inArrClear	#begin cleaning array if end of SymTab has been reached
		          j 	printSymTab
		
inArrClear:	  addi	$t0, $t0, 4		#increment the LOC by 1
		          la	$a0, inArr		#scrubs the inArr
		          la	$t0, ($a0)
		          addi	$t0, $t0, 100
		
clear:		    sb	$zero, ($a0)		#stores a null byte at each location 
		          addi	$a0, $a0, 1
		          bne	$a0, $t0, clear
		          b main

hex2char:	    sw 	$t0, saveReg($0) # hex digit to process
		          sw 	$t1, saveReg+4($0) # 4-bit mask
		          sw 	$t9, saveReg+8($0)
		          # initialize registers
		          li $t1, 0x0000000f # $t1: mask of 4 bits
		          li $t9, 3 # $t9: counter limit
		
nibble2char:	and $t0, $a0, $t1 # $t0 = least significant 4 bits of $a0
		          # convert 4-bit number to hex char
		          bgt $t0, 9, hex_alpha # if ($t0 > 9) goto alpha
		          # hex char '0' to '9'
		          addi $t0, $t0, 0x30 # convert to hex digit
		          b collect
		
hex_alpha:	  addi $t0, $t0, -10 # subtract hex # "A"
		          addi $t0, $t0, 0x61 # convert to hex char, a..f
		          # save converted hex char to $v0
		
collect:	    sll $v0, $v0, 8 # make a room for a new hex char
		          or $v0, $v0, $t0 # collect the new hex char
		          # loop counter bookkeeping
		          srl $a0, $a0, 4 # right shift $a0 for the next digit
		          addi $t9, $t9, -1 # $t9--
		          bgez $t9, nibble2char
		          # restore registers
		          lw $t0, saveReg($0)
		          lw $t1, saveReg+4($0)
		          lw $t9, saveReg+8($0)
		          jr $ra
		
		
