[ORG 0x00]
[ BITS 16 ]
SECTION .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
    mov ax, 0x1000      ;보호모드 엔트리 포인트의 시작 어드레스(0x10000)
    mov ds, ax  
    mov es, ax

    cli                 ;인터럽트가 발생하지 못하도록 설정
    lgdt [ GDTR ]       ;GDTR 자료구조를 프로세서에 설정하여  GDT테이블을 로드

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   보호모드로 진입
;   Disable Paging, Disable Cache, Internal FT U, Disable Align Check,
;   Enable ProtectedMode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax, 0x4000003B     ;PG=0, CD=1, NW=0, AM=0, WP=0, NE=1, ET=1, TS=1, EM=0, MP=1, PE=1
    mov cr0, eax            ;CR0 컨트롤 레지스터에 플래그를 설정/ 보호모드로 전환(PE = 1 일때 보호모드로 전환됨.)

    ;커널 코드 세그먼트를 0x00을 기준으로 하는 것으로 교체하고 EIP의 값을 0x00을 기준으로 재설정
    ;CS 세그먼트 셀렉터 : EIP
    jmp dword 0x08: (PROTECTEDMODE - $$ + 0x10000)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;   보호모드로 진입
;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[ BITS 32]
PROTECTEDMODE:
    mov ax, 0x10        ;보호모드용 데이터 세그먼트 디스크립터 주소(0x10)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ;STACK을 0x00000000~0x0000FFFF 영역에 64KB로 설정
    mov ss, ax          ;SS(Stack Segment)도 32비트 데이터 세그먼트(0x10)로 설정
    mov esp, 0xFFFE     ; 스택 포인터(ESP)의 시작 주소를 0xFFFE로 지정
    mov ebp, 0xFFFE     ; 베이스 포인터(EBP)도 같은 곳으로 지정

    ;화면에 보호모드로 전환되었다는 메세지 출력
    push (SWITCHSUCCESSMESSAGE - $$ + 0x10000)
    push 2
    push 0
    call PRINTMESSAGE
    add esp, 12

    jmp $

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   함수 코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;메시지를 출력하는 함수
PRINTMESSAGE:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push eax
    push ecx
    push edx

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;   X, Y의 좌표로 비디오 메모리의 어드레스를 계산함
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Y좌표를 이용해서 라인 어드레스를 구함 
    mov eax, dword [ ebp + 12 ]
    mov esi, 160
    mul esi
    mov edi, eax

    ;X좌표를 이용해서 2를 곱한 후 최종 어드레스를 구함
    mov eax, dword [ ebp + 8 ]
    mov esi, 2
    mul esi
    add edi , eax

    ;출력할 문자열의 address
    mov esi, dword [ ebp + 16 ]

.MESSAGELOOP:
    mov cl, byte [ esi ]
    cmp cl, 0
    je .MESSAGEEND
    mov byte [ edi + 0xB8000 ], cl
    add esi, 1
    add edi, 2
    jmp .MESSAGELOOP

.MESSAGEEND:
    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    pop ebp
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   데이터 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 아래의 데이터들을 8바이트에 맞춰 정렬하기 위해 추가
align 8, db 0

;GDTR끝을 8byte로 정렬하기 위해 추가
dw 0x0000

;GDTR 자료구조 정의
GDTR:
    dw GDTEND - GDT - 1         ;아래에 위치하는 GDT 테이블의 전체 크기
    dd (GDT - $$ + 0x10000)     ;아래에 위치하는 GDT 테이블의 시작 어드레스

GDT:
    NULLDescriptor:
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0x00
        db 0x00
        db 0x00

    CODEDESCRIPTOR:
        dw 0xFFFF   ;Limit [15:0]
        dw 0x0000   ;Base [15:0]
        db 0x00     ;Base[23:16]
        db 0x9A     ;P=1, DPL=0, Code Segement, Excute/Read
        db 0xCF     ;G=1, D=1, L=0, Limit[19,16]
        db 0x00     ;Base [31:24]

    DATADESCRIPTOR:
        dw 0xFFFF   ;Limit [15:0]
        dw 0x0000   ;Base [15:0]
        db 0x00     ;Base[23:16]
        db 0x92     ;P=1, DPL=0, Data Segement, Read/Write
        db 0xCF     ;G=1, D=1, L=0, Limit[19,16]
        db 0x00     ;Base [31:24]
GDTEND:

;보호모드로 전환 되었다는 메시지
SWITCHSUCCESSMESSAGE: db 'Switch to Protected Mode(32bit) Success~!!', 0

times 512 - ($ - $$) db 0x00







