; Attention score -- (q*k) / sqrt{d}  
; q, k - fp16 vectors,  d - fp16 number


JMP .start
n:
    DB 3
vec_q:
    DB 1.0_h, 1.0_h, 1.0_h
vec_k:
    DB 1.0_h, 1.0_h, 1.0_h
num_d:
    DB 9.0_h
result:
    DB 0.0_h 
.start:
; === scalar multiplication part ===
    MOV A, vec_q    ; load vector pointer
    MOV B, vec_k    ; load vector pointer

    MOV C, [n]        ; counter 
    FMOV.H FHB, 0.0_h ; acumulator

.calc_loop:

    FMOV.H FHA, [A] 
    FMOV.H FHC, [B]

    FMUL.H FHA, FHC
    FADD.H FHB, FHA ; increase acumulator


    ADD A, 2 
    ADD B, 2
    DEC C
    JNZ .calc_loop
    
; === sqrt calculation part ===
   FMOV.H   FHA, [num_d]
   FSQRT.H  FHA   ; sqrt{d}
   
; === division part ===
   FDIV.H FHB, FHA ; (d*k) / sqrt{d}
   
; === write to memory part === 
   FMOV.H [result], FHB
