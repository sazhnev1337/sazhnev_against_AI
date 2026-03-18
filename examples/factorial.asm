JMP start

n:   DB 5       ; вычислить 5! = 120
res: DB 0

start:
    MOV C, [n]
    MOV A, 1
        
.loop:
    MUL C ; A = A * C
    DEC C 
    JNZ .loop

    MOV [res], A

    HLT
