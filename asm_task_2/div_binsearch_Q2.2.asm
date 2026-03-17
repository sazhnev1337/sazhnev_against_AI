; a/b = q  =>  find q: q * b = a
; Q2.2: a = 3.75 = 0b000011.11 = 0x0F
;       b = 1.25 = 0b000001.01 = 0x05
;       q = a / b = 3
JMP start
a_val:
	DB 0x0F
b_val:
	DB 0x05
div_res: 
	DB 0x00
start:
    MOV A, [a_val]
    MUL 4        ; hi -> reg "A"
    MOV D, 0     ; lo -> reg "D"
.loop:
    PUSH A      ; save hi value on stack
    ADD A, D
    SHR A, 1    ; mid = (lo + hi) / 2
    MOV C, A    ; mid -> reg "C"

    MOV B, [b_val]
    MUL B           ; product = mid * b_raw -> reg "A"
    MOV B, [a_val]  ; a -> reg "B"

    SHL B, 2        ; B = a_raw * 4 = a_scaled    by Claude
    CMP A, B        ; compare A & B (mid*b_raw & a_raw)
    JC .less        ; mid*b_raw < a_raw
    JZ .equal       ; mid*b_raw = a_raw
    JMP .greater    ; mid*b_raw > a_raw
.less:
    ; A < B
    POP A
    MOV D, C      ; update lo 
    JMP .done
.equal:
    ; A = B
    MOV [div_res], C
    JMP .termination
.greater:
    ; A > B
    POP A       
    MOV A, C  ; update hi 
.done:
    MOV B, A        ; B = hi
    SUB B, D        ; B = hi - lo
    CMP B, 1
    JA .loop        ; if hi - lo > 1 — repeat

    ; if we reach here, than hi - lo = 1 =>
    ; => lo is answer
    MOV [div_res], D
.termination:
HLT
