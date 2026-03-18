; Задание 2: W[m,n] × x[n] → res[m]
; Входные данные в OFP8 E4M3, результат в float16.
;
; Регистры при входе в start (из шаблона):
;   A = адрес mat
;   B = адрес vec
;   C = адрес переменной m (не значение!)
;   D = адрес res
;
; Стек-фрейм (инициализируется в start, живёт всё время работы):
;   [SP+1] = res_ptr      — текущий адрес записи в res
;   [SP+2] = mat_ptr      — адрес начала текущей строки матрицы
;   [SP+3] = row_counter  — сколько строк осталось обработать
;
; FP-регистры (phys=0 = FA, phys=1 = FB):
;   FQA  [7:0]  phys=0 — элемент матрицы a[row][col], OFP8 E4M3
;   FQE  [7:0]  phys=1 — элемент вектора x[col],     OFP8 E4M3
;   FHA  [15:0] phys=0 — накопитель строки,           float16
;   FHB  [31:16] phys=0 — произведение a*x,           float16
;   FHC  [15:0] phys=1 — a[row][col] как float16      (ВНИМАНИЕ: перекрывает FQE!)
;   FHD  [31:16] phys=1 — x[col] как float16
;
; Порядок FCVT внутри inner_loop:
;   Сначала FQE → FHD (пока FQE жива),
;   потом  FQA → FHC (запись в FHC затирает FQE — но она уже не нужна).

JMP start

m:   DB 2
n:   DB 2

mat: DB 1.0_o3, 0.0_o3
     DB 0.0_o3, 1.0_o3

vec: DB 2.0_o3, 1.0_o3

res: DB 0.0_h, 0.0_h

start:
    MOV A, mat
    MOV B, vec
    MOV C, m
    MOV D, res

    ; Инициализируем стек-фрейм.
    ; A, B, D уже содержат нужные адреса.
    ; Значение row_counter читаем через C (адрес m) — не трогая A, B, D.


    ; Кладём на стек: row_counter, mat_ptr, res_ptr
    PUSH C                  ; [SP+3 после всех push] row_counter = m
    PUSH A                  ; [SP+2 после всех push] mat_ptr = адрес mat
    PUSH D                  ; [SP+1]                 res_ptr = адрес res
    ; Стек: [SP+1]=res_ptr, [SP+2]=mat_ptr, [SP+3]=row_counter

.outer_loop:
    ; Инициализируем аккумулятор строки FHA = 0.0
    FMOV.H FHA, 0.0_h

    ; Загружаем mat_ptr и res_ptr из стека
    MOV A, [SP+2]           ; A = mat_ptr (начало текущей строки)
    MOV D, [SP+1]           ; D = res_ptr

    ; Счётчик столбцов: читаем значение n из памяти
    MOV C, [n]              ; C = n = 3

    ; B всегда указывает на начало vec (не меняется между строками)
    MOV B, vec

.inner_loop:
    ; Загружаем a[row][col] → FQA (OFP8, 1 байт)
    FMOV.O3 FQA, [A]

    ; Загружаем x[col] → FQE (OFP8, 1 байт)
    FMOV.O3 FQE, [B]

    ; Конвертируем: сначала FQE → FHD, потом FQA → FHC
    ; (FHC перекрывает FQE в phys=1, поэтому FQE конвертируем первой)
    FCVT.H.O3 FHD, FQE     ; x[col]    → float16 в FHD
    FCVT.H.O3 FHB, FQA     ; a[row][col] → float16 в FHC (FQE затёрта, но уже не нужна)

    ; FHB = a[row][col] * x[col]
    FMUL.H FHB, FHD

    ; FHA += FHB
    FADD.H FHA, FHB

    INC A                   ; следующий элемент строки матрицы
    INC B                   ; следующий элемент вектора

    DEC C
    CMP C, 0
    JNZ .inner_loop

    ; --- Конец inner_loop ---
    ; A сейчас = mat_ptr + n (начало следующей строки) — используем как новый mat_ptr
    ; D = res_ptr (не менялся в inner_loop)

    ; Записываем результат строки (float16 = 2 байта) в res[row]
    FMOV.H [D], FHA

    ; Обновляем res_ptr: +2 байта (float16)
    ADD D, 2
    MOV [SP+1], D

    ; Обновляем mat_ptr: A уже указывает на начало следующей строки
    MOV [SP+2], A

    ; Декремент row_counter
    MOV A, [SP+3]
    DEC A
    MOV [SP+3], A

    CMP A, 0
    JNZ .outer_loop

    ; Чистим стек
    POP A
    POP A
    POP A

    HLT
