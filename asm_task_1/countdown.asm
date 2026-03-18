; Обратный отсчёт. Выведите в консоль: 5 4 3 2 1 0 .
; Подсказка: ASCII код символа '0' = 48. 
; Чтобы превратить цифру в символ — прибавьте 48. 

	MOV A, 232    ; console start
	MOV B, 5      ; счётчик

.loop:

    MOV C, B
    ADD C, 48
    MOV [A], C
    INC A

    MOV [A], 32
    INC A    
    DEC B
    JNZ .loop

    MOV [A], 48

	HLT
