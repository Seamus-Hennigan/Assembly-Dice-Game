; DiceGame.inc - Include file for the DiceGame

; ---- Game constants ----
STARTING_BALANCE   EQU 100
BET_AMOUNT         EQU 10        ; default bet (player can change it)
BORROW_AMOUNT      EQU 100       ; loan offered when broke
MAX_NAME_LEN       EQU 32
MAX_FILENAME_LEN   EQU 40

; ---- Menu choice characters ----
MENU_NEW           EQU '1'
MENU_LOAD          EQU '2'
MENU_QUIT          EQU '3'
GAME_ROLL          EQU '1'
GAME_SAVE          EQU '2'
GAME_SET_BET       EQU '3'

; ---- Console / Win32 constants ----
STD_OUTPUT_HANDLE  EQU -11
COLOR_GREEN        EQU 0Ah
COLOR_RED          EQU 0Ch
COLOR_WHITE        EQU 7

GENERIC_READ           EQU 80000000h
GENERIC_WRITE          EQU 40000000h
CREATE_ALWAYS          EQU 2
OPEN_EXISTING          EQU 3
FILE_ATTRIBUTE_NORMAL  EQU 80h
INVALID_HANDLE_VALUE   EQU -1

; ---- MASM procedure prototypes ----
RunGame         PROTO C
MainMenu        PROTO
NewGame         PROTO
LoadGame        PROTO
GameMenu        PROTO
RollAndDisplay  PROTO
SaveGame        PROTO
GetPlayerName   PROTO
SetBet          PROTO

; ---- C++ exported function prototypes (cdecl) ----
rollDice        PROTO C, die1Out:PTR DWORD, die2Out:PTR DWORD
applyBet        PROTO C, bal:DWORD, total:DWORD, bet:DWORD
classifyRoll    PROTO C, total:DWORD

; ---- Convenience macro: print a null-terminated string via Irvine ----
mPrint MACRO textLabel
    push edx
    mov  edx, OFFSET textLabel
    call WriteString
    pop  edx
ENDM
