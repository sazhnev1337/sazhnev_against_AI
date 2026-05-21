start:
        ; ----- Embedding loop -----
        MOV     D, 0
        MOV     DP, 16
.emb_loop:
        MOV     A, [D + 0]
        SHL     A, 4
        MOV     B, 1
        VSET    VA, B, A
        MOV     A, D
        SHL     A, 4
        MOV     B, 2
        VSET    VB, B, A
        MOV     B, 17
        VSET    VC, B, A
        VSET    VL, 0, 8
        VADD.H  VC, VA, VB
        VWAIT
        INC     D
        CMP     D, 9
        JNZ     .emb_loop

        ; ----- Q matrix loop (вставленный код выше) -----
        MOV     D, 0
.i_loop:
        ; ... (вставить полный код Q-матрицы) ...

        HLT

; ----- Данные -----
@page 1
token_emb:
@include "weights_split/token_emb.bin"
@page 2
pos_emb:
@include "weights_split/pos_emb.bin"
@page 3
W_q:
@include "weights_split/W_q.bin"
@page 16
tokens: DB 0, 1, 0, 3, 4, 0, 1, 0, 3
