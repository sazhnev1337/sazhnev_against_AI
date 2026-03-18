	JMP start
data:
	DB 10, 20, 30, 15, 25
len:
	DB 5
start:
	MOV A, 0      ; sum
	MOV B, data   ; pointer
	MOV C, [len]  ; counter

.calc_loop:
    
    ADD A, [B]        

    INC B
    DEC C
    JNZ .calc_loop 

; === console print ===

    MOV D, 232  ; console pointer
    MOV C, 3    ; new counter

.push_loop:

    PUSH A
    DIV 10

    DEC C
    JNZ .push_loop


    MOV C, 2    ; new counter 

    MOV A, [SP+1]  
    ADD A, 48
    MOV [D], A ; most sangnificant digit

    POP A   ; initial state for pop_loop

.pop_loop:
    INC D

    MOV B, [SP+1]
    MUL 10
    SUB B, A

    ADD B, 48
    MOV [D], B

    POP A
    DEC C
    JNZ .pop_loop
    

	HLT
