; Q2.2: a = 1.5 = 000001.10 = 0x06
;       b = 0.5 = 000000.10 = 0x02
JMP start

a_val:
	DB 0x06
b_val:
	DB 0x02
res:
	DB 0x00

start:
	MOV A, [a_val]
	MOV B, [b_val]

    MUL B

    SHR A, 2
    
    MOV [res], A

	HLT

; res = 1.5 * 0.5 = 0.75 = 000000.11 = 0x03
