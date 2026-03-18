	JMP start
vec_a:
	DB 3, 5, 2
vec_b:
	DB 4, 1, 6
len:
	DB 3
start:
	MOV D, 0      ; результат
	MOV C, 3      ; индекс

    MOV A, vec_a
    MOV B, vec_b

.calc_loop:
    
    PUSH A
    MOV A, [A]

    MUL [B] 
    ADD D, A

    POP A

    INC A
    INC B

    DEC  C
    JNZ .calc_loop 

    MOV A, D

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
