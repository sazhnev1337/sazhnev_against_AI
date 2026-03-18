; Задание 1: скалярное произведение двух OFP8 E4M3 векторов,
; результат накапливается в acc как float16.
;
; Регистры при входе в start:
;   A = vec_a (адрес первого элемента)
;   B = vec_b (адрес первого элемента)
;   C = 3     (длина вектора)
;   D = acc   (адрес аккумулятора float16, 2 байта)
;
; FP-регистры:
;   FQE — текущий элемент vec_a  (OFP8 E4M3)
;   FQF — текущий элемент vec_b  (OFP8 E4M3, phys=1)
;   FHA — acc (float16, phys=0 low half)
;   FHB — промежуточное произведение float16 (phys=0 high half)
;
; Алгоритм (за одну итерацию):
;   1. Загружаем a[i] → FQE (OFP8)
;   2. Загружаем b[i] → FQF (OFP8)
;   3. FCVT.H.O3 FHD, FQE   ; a_i → float16
;   4. FCVT.H.O3 FHB, FQF   ; b_i → float16
;   5. FMUL.H FHB, FHD       ; FHB = a_i * b_i
;   6. FADD.H FHA, FHB       ; FHA += a_i * b_i
;   7. Инкремент A, B; декремент C; если C != 0 — повтор
;   8. Сохранить FHA → [D]

JMP start

vec_a: DB 2.0_o3, 3.0_o3, 1.5_o3

vec_b: DB 1.75_o3, 1.0_o3, 2.5_o3

acc:   DB 0.0_h

start:
    MOV A, vec_a
    MOV B, vec_b
    MOV C, 3
    MOV D, acc

    ; Инициализируем аккумулятор FHA = 0.0 (float16)
    FMOV.H FHA, 0.0_h

.loop:
    ; Загружаем a[i] в FQA (OFP8 E4M3, 1 байт)
    FMOV.O3 FQE, [A]

    ; Загружаем b[i] в FQE (OFP8 E4M3, на phys=1)
    FMOV.O3 FQF, [B]

    ; Конвертируем a[i]: OFP8 → float16
    FCVT.H.O3 FHD, FQE

    ; Конвертируем b[i]: OFP8 → float16
    FCVT.H.O3 FHB, FQF

    ; FHB = a[i] * b[i]
    FMUL.H FHB, FHD

    ; FHA += a[i] * b[i]
    FADD.H FHA, FHB

    ; Следующие элементы
    INC A
    INC B

    ; Декремент счётчика и проверка
    DEC C
    CMP C, 0
    JNZ .loop

    ; Сохраняем результат: FMOV хранит float16 (2 байта) по адресу D
    FMOV.H [D], FHA

    HLT
