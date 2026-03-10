; Задание 2: W[m,n] × x[n] → res[m], форматы OFP8 E4M3 → float16
;
; Стратегия хранения состояния:
;   Всё внешнее состояние держим на стеке.
;   Стек при входе в outer_loop (снизу вверх, т.е. от SP+N к SP):
;     [SP+3] = row_counter (оставшееся количество строк)
;     [SP+2] = mat_ptr     (адрес начала текущей строки матрицы)
;     [SP+1] = res_ptr     (адрес текущей ячейки результата)
;   --- всё остальное выше ---
;
;   Регистры внутри inner_loop:
;     A = текущий ptr матрицы (col scan)
;     B = текущий ptr вектора (col scan)
;     C = col_counter (обратный счёт от n до 0)
;     D = временный / не используется
;   FP:
;     FQA — элемент матрицы OFP8
;     FQE — элемент вектора OFP8
;     FHC — a_ij float16
;     FHD — x_j  float16
;     FHB — произведение
;     FHA — накопитель строки

JMP start

m:   DB 2
n:   DB 3

mat: DB 1.0_o3, 2.0_o3, 0.5_o3
     DB 1.5_o3, 1.0_o3, 2.0_o3

vec: DB 2.0_o3, 1.0_o3, 1.5_o3

res: DB 0.0_h, 0.0_h

start:
    MOV A, mat
    MOV B, vec
    MOV C, m
    MOV D, res

    ; --- Инициализируем стек-фрейм ---
    ; Читаем значение m → A
    MOV A, [m]              ; A = m = 2

    ; Кладём на стек: row_counter, mat_ptr, res_ptr
    ; Порядок: сначала row_counter (глубже), потом mat_ptr, потом res_ptr
    PUSH A                  ; [стек-3 снизу] row_counter = m

    MOV A, mat
    PUSH A                  ; [стек-2 снизу] mat_ptr

    MOV A, res
    PUSH A                  ; [стек-1 снизу] res_ptr
    ; Стек (вершина = SP+1): [res_ptr] [mat_ptr] [row_counter]
    ; т.е. [SP+1]=res_ptr, [SP+2]=mat_ptr, [SP+3]=row_counter

.outer_loop:
    ; Инициализируем аккумулятор FHA = 0.0 (float16)
    FMOV.H FHA, 0.0_h

    ; Загружаем mat_ptr → A, res_ptr → D
    MOV A, [SP+2]           ; A = mat_ptr (начало текущей строки)
    MOV D, [SP+1]           ; D = res_ptr

    ; Загружаем n → C (счётчик столбцов)
    MOV C, [n]              ; C = n = 3

    ; B = vec (начало вектора — всегда сначала)
    MOV B, vec

.inner_loop:
    ; Загружаем a[row][col] → FQA
    FMOV.O3 FQA, [A]

    ; Загружаем x[col] → FQE
    FMOV.O3 FQE, [B]

    ; Конвертируем OFP8 → float16
    FCVT.H.O3 FHC, FQA     ; a_ij → float16 в FHC
    FCVT.H.O3 FHD, FQE     ; x_j  → float16 в FHD

    ; FHB = a_ij * x_j
    FMOV.H FHB, FHC
    FMUL.H FHB, FHD

    ; FHA += a_ij * x_j
    FADD.H FHA, FHB

    INC A                   ; следующий столбец матрицы
    INC B                   ; следующий элемент вектора

    DEC C
    CMP C, 0
    JNZ .inner_loop

    ; --- Конец inner_loop ---
    ; A сейчас = mat_ptr + n (начало следующей строки) ✓
    ; FHA = dot product текущей строки

    ; Записываем float16 результат по адресу res_ptr
    ; D = res_ptr (загружен выше и не изменялся в inner_loop)
    FMOV.H [D], FHA

    ; Обновляем res_ptr: res_ptr += 2 (float16 = 2 байта)
    ADD D, 2
    MOV [SP+1], D           ; сохранить обновлённый res_ptr

    ; Обновляем mat_ptr = A (уже указывает на след. строку)
    MOV [SP+2], A

    ; Декремент row_counter
    MOV A, [SP+3]
    DEC A
    MOV [SP+3], A

    CMP A, 0
    JNZ .outer_loop

    ; --- Очищаем стек (3 значения) ---
    POP A
    POP A
    POP A

    HLT
