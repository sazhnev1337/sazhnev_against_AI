JMP start

arr: DB 4, 9, 2, 7, 1, 6
res: DB 0

start:

    MOV A, arr   ; array pointer
    MOV B, 0     ; clean variable
    MOV C, 6     ; counter init

.loop:

    CMP B, [A]   ; set flag C = 1 if B < [A]  
    JNC Bmore    ; jump if flag C = 0

    ; B less then [A]
    MOV B, [A]

.Bmore:
    ; B more then [A]
    INC A
    DEC C
    JNZ .loop   ; end of cycle

    MOV [res], B

    HLT
