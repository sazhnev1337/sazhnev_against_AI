; Q4.4: a = 2.5 (0x28), b = 1.25 (0x14)
JMP start

a_val:
	DB 0x28
b_val:
	DB 0x14

start:
	MOV A, [a_val]
	MOV B, [b_val]

    ADD A, B
    MOV C, A

	MOV A, [a_val]

    SUB A, B
    MOV D, A

	HLT

;  a + b = 2.5 + 1.25 = 3.75 = 0011.1100 = 3C
;  a - b = 2.5 - 1.25 = 1.25 = 0001.0100 = 14
