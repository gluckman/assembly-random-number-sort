TITLE CS 271 Assignment 5     (Program05.asm)

;// Author: David Gluckman
;// Due date: 5/22/16
;// CS 271 Section 400 Spring 2016                 Date: 5/15/16
;// Description: This program demonstrates indirect addressing, 
;// passing parameters, generating "random" numbers, and working
;// with arrays in a MASM program that generates, displays, and
;// sorts random integers.

INCLUDE Irvine32.inc

MIN = 10	;// Requested amount range minimum
MAX = 200	;// Requested amount range maximum
LO	= 100	;// Random number range low
HI	= 999	;// Random number range high

.data

pTitle		BYTE	"Random Number Generator             Programmed by David Gluckman", 0
inst1		BYTE	"This program generates random numbers in the range [", 0
rangeDots	BYTE	" .. ", 0
inst2		BYTE	"],", 0
inst3		BYTE	"displays the original list, sorts the list, and calculates the", 0
inst4		BYTE	"median value. Finally, it displays the list sorted in descending order.", 0

prompt1		BYTE	"How many numbers should be generated? [", 0
prompt2		BYTE	"]: ", 0
inputError	BYTE	"Invalid input, please try again.", 0
randCnt		DWORD	?	;// Number of random numbers requested by user

randArray	DWORD	MAX dup(?)		;// Uninitialized array of size MAX

titleUnsort	BYTE	"The unsorted random numbers are: ", 0
titleMed	BYTE	"The median is: ", 0
period		BYTE	".", 0
titleSort	BYTE	"The sorted random numbers are: ", 0
perLine		DWORD	10	;// Number of array elements to print per line


.code
main PROC

	push	OFFSET inst4
	push	OFFSET inst3
	push	OFFSET inst2
	push	OFFSET rangeDots
	push	OFFSET inst1
	push	OFFSET pTitle
	call	introduction	;// Display title and instructions

	push	OFFSET inputError
	push	OFFSET prompt2
	push	OFFSET rangeDots
	push	OFFSET prompt1
	push	OFFSET randCnt
	call	getData			;// Get request number from user

	push	OFFSET randArray
	push	randCnt
	call	fillArray		;// Fill array with random numbers in range

	push	OFFSET randArray
	push	perLine
	push	randCnt
	push	OFFSET titleUnsort
	call	dispArray		;// Display the unsorted array

	push	OFFSET randArray
	push	randCnt
	call	sortArray		;// Sort numbers in descending order

	push	OFFSET randArray
	push	randCnt
	push	OFFSET period
	push	OFFSET titleMed
	call	dispMedian		;// Display the array's median

	push	OFFSET randArray
	push	perLine
	push	randCnt
	push	OFFSET titleSort
	call	dispArray		;// Display the sorted array

	exit	;// exit to operating system
main ENDP


;// Procedure to introduce the random number program
;// receives: pTitle, inst1, inst2, inst3, inst4, and 
;//		rangeDots as references
;// returns: nothing
;// preconditions: none
;// registers changed: none; all saved and restored

introduction PROC
	;// Set up stack frame
	pushad
	mov		ebp, esp

	;// Print title and programmer name
	mov		edx, [ebp + 36]
	call	WriteString
	call	CrLF
	call	CrLF

	;// Print inst1
	mov		edx, [ebp + 40]
	call	WriteString

	;// Print range low
	mov		eax, LO
	call	WriteDec

	;// Print " .. "
	mov		edx, [ebp + 44]
	call	WriteString

	;// Print range high
	mov		eax, HI
	call	WriteDec

	;// Print inst2
	mov		edx, [ebp + 48]
	call	WriteString
	call	CrLF

	;// Print inst3
	mov		edx, [ebp + 52]
	call	WriteString
	call	CrLF

	;// Print inst4
	mov		edx, [ebp + 56]
	call	WriteString
	call	CrLF
	call	CrLF

	;// Restore ebp, return, and adjust stack
	popad
	ret		24
introduction ENDP



;// Procedure to get number of randoms to be generated
;// receives: randCnt, prompt1, prompt2, rangeDots, and
;//		inputError as references
;// returns: randCnt is set as a valid number within the range
;// preconditions: none
;// registers changed: none; all saved and restored

getData PROC
	;// Set up stack frame
	pushad
	mov		ebp, esp

	;// Skip error message on first request
	jmp		startGet

dataInvalid:	;// Return here if data is invalid
	
	;// Print error message before requesting new number
	mov		edx, [ebp + 52]
	call	WriteString
	call	CrLF

startGet:	;// Start here on first request
	
	;// Print prompt1
	mov		edx, [ebp + 40]
	call	WriteString

	;// Print range min
	mov		eax, MIN
	call	WriteDec

	;// Print " .. "
	mov		edx, [ebp + 44]
	call	WriteString

	;// Print range max
	mov		eax, MAX
	call	WriteDec

	;// Print prompt2
	mov		edx, [ebp + 48]
	call	WriteString

	;// Read user entry
	call	ReadDec

	;// Check user entry is valid
	cmp		eax, MIN
	jb		dataInvalid
	cmp		eax, MAX
	ja		dataInvalid

	;// Store valid user entry in randCnt
	mov		edx, [ebp + 36]
	mov		[edx], eax

	;// Restore registers, return, and adjust stack
	popad
	ret		20
getData ENDP


;// Procedure to fill the array with random numbers
;// receives: randCnt as value and randArray as reference
;// returns: randArray is filled with randCnt randoms
;// preconditions: randCnt is between 10 and 200 inclusive
;// registers changed: none; all saved and restored
;// ** code is similar to that in lecture 19/20 and book

fillArray PROC
	;// Set up stack frame
	pushad
	mov		ebp, esp

	;// Set user request as counter
	mov		ecx, [ebp + 36]

	;// Set array address
	mov		edi, [ebp + 40]

	;// Make things "random"
	call	Randomize

randLoop:	;// Loop here to add random array elements

	;// Set random range
	mov		eax, HI
	sub		eax, LO
	inc		eax

	;// Generate random number
	call	RandomRange

	;// Adjust random number
	add		eax, LO

	;// Save random number to array
	mov		[edi], eax

	;// Increment to next array element
	add		edi, TYPE dword

	loop	randLoop

	;// Restore registers, return, and adjust stack
	popad
	ret		8
fillArray ENDP


;// Procedure to sort elements in an array in descending order
;//		using selection sort
;// receives: array as reference, array size as value
;// returns: nothing
;// preconditions: none
;// registers changed: none; all saved and restored

sortArray PROC
	;// Set up stack frame
	pushad
	mov		ebp, esp

	;// Set array size - 1 as counter
	mov		ecx, [ebp + 36]
	dec		ecx

	;// Set array address
	mov		esi, [ebp + 40]

	;// Set outer loop counter to 0
	mov		edx, 0

outer:	;// Start outer sort loop
	;// Set i and j
	mov		edi, edx
	mov		ebx, edx
	inc		ebx

	;// Prepare inner loop counter
	push	ecx
	mov		ecx, [ebp + 36]
	dec		ecx
	sub		ecx, edx

inner:	;// Start inner sort loop

	;// if array[j] > array[i], i = j
	mov		eax, [esi + edi * 4]
	mov		eax, [esi + ebx * 4]
	cmp		eax, [esi + edi * 4]
	jbe		notGreater
	mov		edi, ebx

notGreater:	;// array[j] <= array[i]
	inc		ebx
	loop	inner

	;// Adjust j before swap
	dec		ebx

	;// Swap array[i] and array[k]
	lea		eax, [esi + edx * 4]
	push	eax
	lea		eax, [esi + edi * 4]
	push	eax
	call	exchElems

	;// Return to outer loop
	pop		ecx
	inc		edx
	loop	outer

	;// Restore registers, return, and adjust stack
	popad
	ret		8
sortArray ENDP


;// Procedure to swap two elements in an array
;// receives: two array elements as references
;// returns: nothing
;// preconditions: none
;// registers changed: none; all saved and restored

exchElems PROC
	;// Set up stack frame
	pushad
	mov		ebp, esp

	;// Temporarily store addresses in registers
	mov		eax, [ebp + 36]
	mov		ebx, [ebp + 40]

	;// Dereference values
	mov		edx, [eax]
	mov		edi, [ebx]

	;// Swap and store values
	mov		[eax], edi
	mov		[ebx], edx

	;// Restore registers, return, and adjust stack
	popad
	ret		8
exchElems ENDP


;// Procedure to calculate and display the median of an array
;// receives: text elements and array as references, array size
;//		as value
;// returns: displays median
;// preconditions: none
;// registers changed: none; all saved and restored

dispMedian PROC
	;// Set up stack frame
	pushad
	mov		ebp, esp

	;// Set array address
	mov		esi, [ebp + 48]
	
	;// Print median text
	mov		edx, [ebp + 36]
	call	WriteString

	;// Check if array count is even or odd
	mov		edx, 0
	mov		eax, [ebp + 44]
	mov		ebx, 2
	div		ebx
	cmp		edx, 0
	jz		evenMed

	;// Array count is odd, find median value
	mov		eax, [esi + eax * 4]
	jmp		medianFound

evenMed:	;// Continue here if array count is even
	;// Calculate average of middle elements
	mov		ebx, eax
	mov		eax, [esi + ebx * 4]	;// Move second mid element to accumulator
	dec		ebx
	add		eax, [esi + ebx * 4]	;// Add first mid element to accumulator
	mov		edx, 0
	mov		ebx, 2
	div		ebx						;// Divide accumulator by 2

	;// Round up if necessary
	cmp		edx, 1
	jne		medianFound
	inc		eax

medianFound:	;// Continue here after median has been found
	;// Print the median
	call	WriteDec

	;// Print a period
	mov		edx, [ebp + 40]
	call	WriteString
	call	CrLF

	;// Restore registers, return, and adjust stack
	popad
	ret		16		
dispMedian ENDP


;// Procedure to display an array with a title
;// receives: title and array as references, array size and
;//		line length as values
;// returns: nothing
;// preconditions: none
;// registers changed: none; all saved and restored

dispArray PROC
	;// Set up stack frame
	pushad
	mov		ebp, esp

	;// Print title
	call	CrLF
	mov		edx, [ebp + 36]
	call	WriteString
	call	CrLF

	;// Set user request as counter
	mov		ecx, [ebp + 40]

	;// Set array address
	mov		edi, [ebp + 48]

printLoop:	;// Return here to print next element

	;// Print array element
	mov		eax, [edi]
	call	WriteDec
	mov		al, TAB
	call	WriteChar

	;// Increment to next array element
	add		edi, TYPE dword

	;// Check if line break needed
	mov		edx, 0
	mov		eax, [ebp + 40]
	sub		eax, ecx
	inc		eax
	mov		ebx, [ebp + 44]
	div		ebx
	cmp		edx, 0
	jnz		noBreak
	cmp		ecx, 1
	je		noBreak

	;// Print line break
	call	CrLF

noBreak : ;// Continue here when no line break printed

	;// Print next element
	loop	printLoop

	;// Print newlines
	call	CrLF
	call	CrLF

	;// Restore registers, return, and adjust stack
	popad
	ret		16
dispArray ENDP


END main
