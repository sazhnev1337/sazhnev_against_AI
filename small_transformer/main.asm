; ============================================================
; Параметры matvec (page 0, адреса 0xE0-0xE7)
; ============================================================
; [0xE0] src_page
; [0xE1] weight_page
; [0xE2] dst_page
; [0xE3] n_rows
; [0xE4] n_cols
; [0xE5] inner_dim       (для VL)
; [0xE6] inner_stride    (= inner_dim*2, шаг между строками входа)
; [0xE7] dst_row_stride  (= n_cols*2, шаг между строками выхода)

start:
        ; ===== Embedding =====
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

        ; ===== Параметры одинаковые для Q, K, V =====
        MOV     DP, 0
        MOV     A, 17
        MOV     [0xE0], A           ; src_page = 17 (X)
        MOV     A, 18
        MOV     [0xE2], A           ; dst_page = 18 (Q сначала)
        MOV     A, 9
        MOV     [0xE3], A           ; n_rows = 9
        MOV     A, 8
        MOV     [0xE4], A           ; n_cols = 8
        MOV     [0xE5], A           ; inner_dim = 8
        MOV     A, 16
        MOV     [0xE6], A           ; inner_stride = 16
        MOV     [0xE7], A           ; dst_row_stride = 16

        ; ===== Q = X @ W_q^T =====
        MOV     A, 3
        MOV     [0xE1], A           ; weight_page = 3 (W_q)
        CALL    matvec

        ; ===== K = X @ W_k^T =====
        MOV     A, 4
        MOV     [0xE1], A           ; weight_page = 4 (W_k)
        MOV     A, 19
        MOV     [0xE2], A           ; dst_page = 19 (K)
        CALL    matvec

        ; ===== V = X @ W_v^T =====
        MOV     A, 5
        MOV     [0xE1], A           ; weight_page = 5 (W_v)
        MOV     A, 20
        MOV     [0xE2], A           ; dst_page = 20 (V)
        CALL    matvec

        HLT

; ============================================================
; matvec — Y[i,j] = dot(X[i,:], W[j,:])
; ============================================================
matvec:
        MOV     DP, 0
        MOV     B, 0
        MOV     A, [0xE5]
        VSET    VL, B, A            ; VL = inner_dim

        MOV     D, 0                ; i = 0
.mv_i:
        ; VA = src_page*256 + i*inner_stride
        MOV     A, D
        MUL     [0xE6]              ; A = i * inner_stride
        MOV     B, [0xE0]
        VSET    VA, B, A

        MOV     C, 0                ; j = 0
.mv_j:
        ; VB = weight_page*256 + j*inner_stride
        MOV     A, C
        MUL     [0xE6]              ; A = j * inner_stride
        MOV     B, [0xE1]
        VSET    VB, B, A

        ; VC = dst_page*256 + i*dst_row_stride + j*2
        MOV     A, D
        MUL     [0xE7]              ; A = i * dst_row_stride
        MOV     B, C
        SHL     B, 1                ; B = j*2
        ADD     A, B                ; A = i*dst_row_stride + j*2
        MOV     B, [0xE2]
        VSET    VC, B, A

        VDOT.H  VC, VA, VB
        VWAIT

        INC     C
        MOV     A, [0xE4]
        CMP     C, A
        JNZ     .mv_j

        INC     D
        MOV     A, [0xE3]
        CMP     D, A
        JNZ     .mv_i

        RET

; ============================================================
; Данные
; ============================================================
@page 1
token_emb:
@include "token_emb.bin"
@page 2
pos_emb:
@include "pos_emb.bin"
@page 3
W_q:
@include "W_q.bin"
@page 4
W_k:
@include "W_k.bin"
@page 5
W_v:
@include "W_v.bin"
@page 16
tokens: DB 0, 1, 0, 3, 4, 0, 1, 0, 3
