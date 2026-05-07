; Project Name: Final Project - Dice Game
; Author: Seamus Hennigan


.386
.model flat, stdcall
.stack 4096
INCLUDE Irvine32.inc						;Brings in the Irvine32 library
INCLUDE DiceGame.inc						;Our own custom include file


.data
; ---- Game state ----
playerName    BYTE MAX_NAME_LEN     DUP(0)	;Holds the player's typed-in name
fileName      BYTE MAX_FILENAME_LEN DUP(0)	;Holds "playername.txt" for save/load
balance       DWORD ?						;Current $ in the player's account
die1          DWORD ?						;First die result (1-6)
die2          DWORD ?						;Second die result (1-6)
rollTotal     DWORD ?						;Sum of die1 + die2
betAmount     DWORD BET_AMOUNT				;Player's chosen bet (defaults to $10)
bytesIO       DWORD 0						;Bytes read/written by Win32 file calls
hStdOut       DWORD 0						;Console output handle for color changes
fileBuf       BYTE  16 DUP(0)				;Scratch buffer for ASCII balance digits

; ---- Strings (reused / extended from Chap6DiceGame Main.asm) ----
msgTitle      BYTE  "============================", 13, 10
              BYTE  "        DICE GAME", 13, 10
              BYTE  "============================", 13, 10, 0

msgMain       BYTE  13, 10, "MAIN MENU", 13, 10
              BYTE  "  1) Create a New Game", 13, 10
              BYTE  "  2) Load a Saved Game", 13, 10
              BYTE  "  3) Quit", 13, 10
              BYTE  "Choice: ", 0

msgGame       BYTE  13, 10, "GAME MENU", 13, 10
              BYTE  "  1) Roll Dice", 13, 10
              BYTE  "  2) Save Game", 13, 10
              BYTE  "  3) Set Bet Amount", 13, 10
              BYTE  "Choice: ", 0

msgPromptName BYTE  "Enter player name: ", 0
msgWelcome    BYTE  13, 10, "Welcome, ", 0
msgBalance    BYTE  13, 10, "Current Balance: $", 0
msgCurBet     BYTE  "    Current Bet: $", 0
msgBetPrompt  BYTE  13, 10, "Enter new bet amount: $", 0
msgBetSet     BYTE  "Bet amount updated.", 13, 10, 0
msgBetBad     BYTE  "Bet must be a positive number. Bet unchanged.", 13, 10, 0
msgBorrow     BYTE  13, 10, "Borrow $100 to keep playing? (Y/N): ", 0
msgBorrowed   BYTE  13, 10, "Loan approved. Good luck!", 13, 10, 0

msgDie1       BYTE  13, 10, "    Die #1: ", 0
msgDie2       BYTE  "    Die #2: ", 0
msgTotal      BYTE  "    TOTAL: ", 0

msgWinner     BYTE  13, 10, "Winner!! New Total: $", 0
msgLose       BYTE  13, 10, "Sorry, you lose!! New Total: $", 0
msgPush       BYTE  13, 10, "PUSH!! New Total: $", 0

msgBroke      BYTE  13, 10, "You're Broke!", 13, 10, 0
msgSaved      BYTE  13, 10, "Game saved.", 13, 10, 0
msgLoaded     BYTE  13, 10, "Game loaded.", 13, 10, 0
msgLoadFail   BYTE  13, 10, "Could not find a save for that player.", 13, 10, 0
msgGoodbye    BYTE  13, 10, "Thanks for playing!", 13, 10, 0

extTxt        BYTE  ".txt", 0				;Extension we append to the player name

.code

RunGame PROC C
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE	;Win32 API: grab console output handle
	mov hStdOut, eax						;Save handle for later color changes

	mPrint msgTitle							;Prints the game title banner

MainLoop:
	call MainMenu							;Shows menu, returns choice in AL
	cmp al, MENU_NEW						;Was it '1' (New Game)?
	je  doNew								;Yes -> jump to NewGame
	cmp al, MENU_LOAD						;Was it '2' (Load Game)?
	je  doLoad								;Yes -> jump to LoadGame
	cmp al, MENU_QUIT						;Was it '3' (Quit)?
	je  doQuit								;Yes -> jump to quit path
	jmp MainLoop							;Otherwise ignore and re-prompt
doNew:
	call NewGame							;Run the new-game flow
	jmp  MainLoop							;Back to the main menu when it returns
doLoad:
	call LoadGame							;Run the load-game flow
	jmp  MainLoop							;Back to the main menu when it returns
doQuit:
	mPrint msgGoodbye						;Prints "Thanks for playing!"
	ret										;Returns to C++ main
RunGame ENDP


MainMenu PROC
	mPrint msgMain							;Prints the main menu options
	call ReadChar							;Irvine: reads one keypress into AL
	call WriteChar							;Echo the typed character
	call Crlf								;Move to the next line
	ret										;Return with choice still in AL
MainMenu ENDP


NewGame PROC
	call GetPlayerName						;Asks for name, builds "name.txt"

	mov balance, STARTING_BALANCE			;Start the player off with $100
	mov betAmount, BET_AMOUNT				;Reset bet to default $10

	mPrint msgWelcome						;Prints "Welcome, "
	mov  edx, OFFSET playerName				;Point EDX at the typed name
	call WriteString						;Print the player's name
	call Crlf								;Newline

	call GameMenu							;Drop into the game-menu loop
	ret										;Return to RunGame's MainLoop
NewGame ENDP


LoadGame PROC
	LOCAL hFile:DWORD						;Local file handle on the stack

	call GetPlayerName						;Asks for name, builds "name.txt"
	mov betAmount, BET_AMOUNT				;Reset bet to default $10 on load

	; Win32 API: open the save file for reading
	INVOKE CreateFileA, ADDR fileName, GENERIC_READ, 0, 0,					\
						OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
	cmp eax, INVALID_HANDLE_VALUE			;Did the open fail?
	je  LoadFail							;Yes -> show error and return
	mov hFile, eax							;Save the file handle

	INVOKE ReadFile, hFile, ADDR fileBuf, 15, ADDR bytesIO, 0	;Read up to 15 bytes
	INVOKE CloseHandle, hFile				;Done with the file

	; --- Parse ASCII digits in fileBuf into balance ---
	mov  ecx, bytesIO						;ECX = number of bytes we read
	mov  esi, OFFSET fileBuf				;ESI walks through the buffer
	xor  eax, eax							;EAX is our running total (start at 0)

ParseLoop:
	cmp  ecx, 0								;Any bytes left?
	je   ParseDone							;No -> we're done parsing
	movzx ebx, BYTE PTR [esi]				;Grab next byte (zero-extended)
	cmp  bl, '0'							;Is it below '0'?
	jb   ParseDone							;Yes -> stop (CRLF or junk)
	cmp  bl, '9'							;Is it above '9'?
	ja   ParseDone							;Yes -> stop
	sub  bl, '0'							;Convert ASCII digit to value 0-9
	imul eax, eax, 10						;Shift accumulator one decimal place
	add  eax, ebx							;Add this digit
	inc  esi								;Move to next byte
	dec  ecx								;One fewer byte to process
	jmp  ParseLoop							;Keep parsing

ParseDone:
	mov balance, eax						;Save the parsed balance

	mPrint msgLoaded						;Prints "Game loaded."
	call GameMenu							;Drop into the game menu
	ret										;Return to RunGame's MainLoop

LoadFail:
	mPrint msgLoadFail						;Prints "Could not find a save..."
	ret										;Bail back to MainLoop
LoadGame ENDP


GameMenu PROC
GameLoop:
	mPrint msgBalance						;Prints "Current Balance: $"
	mov  eax, balance						;Load the balance
	call WriteDec							;Print it as a decimal
	mPrint msgCurBet						;Prints "    Current Bet: $"
	mov  eax, betAmount						;Load the bet amount
	call WriteDec							;Print it
	call Crlf								;Newline

	mPrint msgGame							;Prints the game-menu options
	call ReadChar							;Read the choice into AL
	call WriteChar							;Echo it
	call Crlf								;Newline

	cmp al, GAME_ROLL						;Was it '1' (Roll Dice)?
	je  doRoll								;Yes -> roll
	cmp al, GAME_SAVE						;Was it '2' (Save Game)?
	je  doSave								;Yes -> save
	cmp al, GAME_SET_BET					;Was it '3' (Set Bet Amount)?
	je  doSetBet							;Yes -> change the bet
	jmp GameLoop							;Otherwise ignore and re-prompt

doRoll:
	call RollAndDisplay						;Rolls dice and updates balance
	cmp  balance, 0							;Did we hit zero or go negative?
	jle  Broke								;Yes -> offer a loan
	jmp  GameLoop							;Otherwise keep playing

doSave:
	call SaveGame							;Write balance to playername.txt
	ret										;Save -> back to main menu

doSetBet:
	call SetBet								;Prompt for a new bet amount
	jmp  GameLoop							;Back to the game menu

Broke:
	mPrint msgBroke							;Prints "You're Broke!"
	mPrint msgBorrow						;"Borrow $100 to keep playing? (Y/N): "
	call ReadChar							;Read the choice into AL
	call WriteChar							;Echo it
	call Crlf								;Newline
	cmp al, 'Y'								;Was it uppercase Y?
	je  BorrowYes							;Yes -> approve the loan
	cmp al, 'y'								;Was it lowercase y?
	je  BorrowYes							;Yes -> approve the loan
	ret										;Anything else -> back to main menu

BorrowYes:
	mov eax, balance						;Load current (broke) balance
	add eax, BORROW_AMOUNT					;Add the $100 loan
	mov balance, eax						;Save it back
	mPrint msgBorrowed						;Prints "Loan approved. Good luck!"
	jmp GameLoop							;Keep playing
GameMenu ENDP


RollAndDisplay PROC
	INVOKE rollDice, ADDR die1, ADDR die2	;C++ fills die1 and die2 (1-6 each)

	mov eax, die1							;Load die1
	add eax, die2							;Add die2 to it
	mov rollTotal, eax						;Save the total

	; --- Print "    Die #1: x    Die #2: y    TOTAL: z" ---
	mPrint msgDie1							;Prints "    Die #1: "
	mov  eax, die1							;Load die1
	call WriteDec							;Print it

	mPrint msgDie2							;Prints "    Die #2: "
	mov  eax, die2							;Load die2
	call WriteDec							;Print it

	mPrint msgTotal							;Prints "    TOTAL: "
	mov  eax, rollTotal						;Load the total
	call WriteDec							;Print it

	; --- Classify and color the outcome line ---
	INVOKE classifyRoll, rollTotal			;C++ returns 1=win, 2=lose, 3=push
	cmp eax, 1								;Was it a win?
	je  Win									;Yes -> jump to Win
	cmp eax, 2								;Was it a loss?
	je  Lose								;Yes -> jump to Lose

PushPath:
	INVOKE SetConsoleTextAttribute, hStdOut, COLOR_WHITE	;Win32: white text
	mPrint msgPush							;Prints "PUSH!! New Total: $"
	jmp ApplyAndPrint						;Skip the win/lose paths
Win:
	INVOKE SetConsoleTextAttribute, hStdOut, COLOR_GREEN	;Win32: green text
	mPrint msgWinner						;Prints "Winner!! New Total: $"
	jmp ApplyAndPrint						;Skip Lose
Lose:
	INVOKE SetConsoleTextAttribute, hStdOut, COLOR_RED		;Win32: red text
	mPrint msgLose							;Prints "Sorry, you lose!! New Total: $"

ApplyAndPrint:
	INVOKE applyBet, balance, rollTotal, betAmount	;C++ returns the new balance in EAX
	mov  balance, eax						;Save the new balance
	call WriteDec							;Print the new balance
	call Crlf								;Newline
	INVOKE SetConsoleTextAttribute, hStdOut, COLOR_WHITE	;Reset color to white
	ret										;Back to GameMenu
RollAndDisplay ENDP


SaveGame PROC
	LOCAL hFile:DWORD						;Local file handle on the stack

	; Win32 API: create/overwrite the save file for writing
	INVOKE CreateFileA, ADDR fileName, GENERIC_WRITE, 0, 0,					\
						CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	cmp eax, INVALID_HANDLE_VALUE			;Did the create fail?
	je  SaveDone							;Yes -> just bail out
	mov hFile, eax							;Save the handle

	; --- Convert balance (DWORD) into ASCII digits in fileBuf ---
	; Build the string from the right so we don't have to reverse it.
	mov eax, balance						;EAX = balance to convert
	mov edi, OFFSET fileBuf					;EDI = start of the buffer
	add edi, 15								;Move to one past the last byte
	mov BYTE PTR [edi], 0					;Drop a null terminator at the end
	dec edi									;Step back to the last writable spot
	mov ebx, 10								;Divisor for "extract one digit"
	xor ecx, ecx							;ECX = digit count (start at 0)

	cmp eax, 0								;Special case: balance == 0?
	jne CvtLoop								;No -> normal conversion
	mov BYTE PTR [edi], '0'					;Yes -> just write a '0'
	inc ecx									;Count it
	jmp CvtDone								;Skip the loop

CvtLoop:
	cmp eax, 0								;Out of digits?
	je  CvtDone								;Yes -> stop
	xor edx, edx							;Clear EDX for division
	div ebx									;EAX /= 10, EDX = remainder digit
	add dl, '0'								;Convert digit value to ASCII
	mov [edi], dl							;Store the ASCII digit
	dec edi									;Move write pointer left
	inc ecx									;One more digit
	jmp CvtLoop								;Keep going

CvtDone:
	inc edi									;EDI now points at the first digit

	; Win32 API: write the digits and close the file
	INVOKE WriteFile, hFile, edi, ecx, ADDR bytesIO, 0	;Write ECX bytes
	INVOKE CloseHandle, hFile				;Close the file
	mPrint msgSaved							;Prints "Game saved."

SaveDone:
	ret										;Back to GameMenu
SaveGame ENDP


GetPlayerName PROC
	mPrint msgPromptName					;Prints "Enter player name: "

	mov  edx, OFFSET playerName				;EDX = where to store the input
	mov  ecx, MAX_NAME_LEN - 1				;ECX = max chars to read
	call ReadString							;Irvine: reads a line, null-terminates

	; --- Copy playerName into fileName ---
	mov esi, OFFSET playerName				;ESI = source (the typed name)
	mov edi, OFFSET fileName				;EDI = destination (filename buffer)
CopyName:
	mov al, [esi]							;Grab next byte of the name
	cmp al, 0								;Was it the null terminator?
	je  AppendExt							;Yes -> stop copying, go append ".txt"
	mov [edi], al							;Otherwise copy the byte
	inc esi									;Advance source pointer
	inc edi									;Advance destination pointer
	jmp CopyName							;Keep copying

	; --- Append ".txt" + null from extTxt ---
AppendExt:
	mov esi, OFFSET extTxt					;ESI = ".txt\0"
CopyExt:
	mov al, [esi]							;Grab next byte of the extension
	mov [edi], al							;Copy it (including the null at the end)
	cmp al, 0								;Was that the null terminator?
	je  CopyExtDone							;Yes -> done
	inc esi									;Advance source pointer
	inc edi									;Advance destination pointer
	jmp CopyExt								;Keep copying

CopyExtDone:
	ret										;Filename is now "<name>.txt\0"
GetPlayerName ENDP


SetBet PROC
	mPrint msgBetPrompt						;Prints "Enter new bet amount: $"
	call ReadInt							;Irvine: reads signed int into EAX
	cmp eax, 0								;Was it zero or negative?
	jle BetBad								;Yes -> reject
	mov betAmount, eax						;Otherwise save the new bet
	mPrint msgBetSet						;Prints "Bet amount updated."
	ret										;Done
BetBad:
	mPrint msgBetBad						;Prints "Bet must be a positive number."
	ret										;Bet stays the same
SetBet ENDP

END
