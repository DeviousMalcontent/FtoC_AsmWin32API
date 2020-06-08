; #########################################################################
; 
; Program: FtoC_AsmWin32API
; Purpose: Converts a temperature to Celsius or Fahrenheit
; Author: Mark Albanese 
; Date: 18 February 2017 / 7 June 2020
; Version: 1.0
; Release: 1
; Language: x86 Assembly / Microsoft Macro Assembler 
; Compiler: MASM32 SDK
; 
; #########################################################################

; Based off FtoC_CppWin32API.
; https://github.com/DeviousMalcontent/FtoC_CppWin32API/blob/master/main.cpp
     .386
     .model flat, stdcall
     option casemap :none   ; case sensitive

; #########################################################################
      include \masm32\include\masm32rt.inc

      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib

; #########################################################################
          
        ;=================
        ; Local prototypes
        ;=================
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        NumProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        CatProc PROTO strBase:DWORD, strAdd:DWORD
    .data?
        inTempStr         dd 512 dup(?) ;Input temperature string to process (holds the value of what the user types in.)
        ;szBuffer           db 20 dup (?)
    .data
        dlgname           db "IDD_MAIN",0
        hInstance         dd 0
       ;debugMsgBoxText   db "Convert pressed",0
        lpfnNumProc       dd 0
        stringBuffer      db 512 dup(?)
        charHyphen        db "-",0
        emptyString       db NULL,0
        IDC_CONVERT       dd 1005
        IDC_EXIT          dd 1006
        IDC_CLEAR         dd 1007
        IDC_CELSIUS       dd 1011
        IDC_FAHRENHEIT    dd 1012
        IDC_TEMPERATURE   dd 1013
        IDC_STATIC2       dd 1016
        IDC_STATIC1       dd 1017
        IDC_RESULT        dd 1019
		
    .code
start:
; #########################################################################
        invoke GetModuleHandle, NULL
        mov hInstance, eax
        
        ; -------------------------------------------
        ; Call the dialog box stored in resource file
        ; -------------------------------------------
        invoke DialogBoxParam,hInstance,ADDR dlgname,0,ADDR WndProc,0

        invoke ExitProcess,eax

; #########################################################################


; -------------------------------------------
; Main window loop
; -------------------------------------------
WndProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
LOCAL r8[2]:REAL8

    Switch uMsg
      Case WM_INITDIALOG
        szText dlgTitle,"Fahrenheit to Celsius"
        invoke SendMessage,hWin,WM_SETTEXT,0,ADDR dlgTitle
        
        invoke SetWindowLong,FUNC(GetDlgItem,hWin,IDC_TEMPERATURE),GWL_WNDPROC,ADDR NumProc
        mov lpfnNumProc, eax

      Case WM_COMMAND
        Switch wParam
          Case IDC_CONVERT      
            invoke GetWindowText,FUNC(GetDlgItem,hWin,IDC_TEMPERATURE),ADDR stringBuffer,512
            
            invoke lstrcpy, ADDR inTempStr, ADDR emptyString
            invoke CatProc, ADDR inTempStr, ADDR stringBuffer
					
			; TODO:
			; Validate input – check that it is a number  
			; Radio buttons – set a default value, check what radio button has been pressed.
			; Convert String to double (REAL8) ref: https://cs.fit.edu/~mmahoney/cse3101/float.html
			; Do calculation:
			
			; ToCelsius: (TemperatureInput - 32) * 5 / 9
			; fsub ADDR inTempStr,32
			; fmul ADDR inTempStr,5
			; fdiv ADDR inTempStr,9 
			; 
			; or something like that...
			; 
			; ToFahrenheit: TemperatureInput * 9 / 5 + 32
			; fmul ADDR inTempStr,9
			; fdiv ADDR inTempStr,5 
			; fadd ADDR inTempStr,32
			
			; Ref: http://www.website.masmforum.com/tutorials/fptute/fpuchap8.htm
			; 
			; Validate output.
            
            invoke SetWindowText,FUNC(GetDlgItem,hWin,IDC_RESULT),ADDR inTempStr
          Case IDC_CLEAR
            invoke SetWindowText,FUNC(GetDlgItem,hWin,IDC_TEMPERATURE),NULL
            invoke SetWindowText,FUNC(GetDlgItem,hWin,IDC_RESULT),NULL
          Case IDC_EXIT
            invoke EndDialog,hWin,0
            
        EndSw
      Case WM_CLOSE
        invoke EndDialog,hWin,0
    EndSw
    return 0
WndProc endp


; ########################################################################

; -------------------------------------------------------------------------------
; Procedure for only allowing numerical input in to edit control (Edit Text)
; -------------------------------------------------------------------------------
NumProc proc hCtl:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD

    LOCAL Buffer[32]:BYTE

    ; -----------------------------
    ; Process control messages here
    ; -----------------------------
    .if uMsg == WM_CHAR
        .if wParam == 8
            jmp accept
        .endif

        .if wParam == "."

            invoke SendMessage,hCtl,WM_GETTEXT,sizeof Buffer,ADDR Buffer

            mov ecx, sizeof Buffer
            lea esi, Buffer
          @xxx:
            lodsb

            cmp al, "."
            jne @xx1
              return 0
            @xx1:

            dec ecx
            cmp ecx, 0
            jne @xxx

            jmp accept
        .endif
        
        .if wParam == "-"
            invoke SendMessage,hCtl,WM_GETTEXT,sizeof Buffer,ADDR Buffer

            mov ecx, sizeof Buffer
            lea esi, Buffer
          @xx2:
            lodsb

            cmp al, charHyphen
            jne @xx3
              return 0
            @xx3:

            dec ecx
            cmp ecx, 0
            jne @xx2
            
            invoke lstrcpy, ADDR inTempStr, ADDR charHyphen
            invoke CatProc, ADDR inTempStr, ADDR Buffer
            invoke SendMessage,hCtl,WM_SETTEXT,sizeof inTempStr,ADDR inTempStr
            invoke SendMessage,hCtl,EM_SETSEL,3,3
            return 0
        .endif

        .if wParam < "0"
            return 0
        .endif

        .if wParam > "9"
            return 0
        .endif

    .endif

    accept:

    invoke CallWindowProc,lpfnNumProc,hCtl,uMsg,wParam,lParam
    
    ret
NumProc endp

; -------------------------------------------
; Procedure for string concatenation.
; -------------------------------------------
CatProc proc strBase:DWORD, strAdd:DWORD
    mov edi, strBase
    mov al, 0
    repne scasb
    dec edi
    mov esi, strAdd
    @@:
        mov al, [esi]
        mov [edi], al
        inc esi
        inc edi
        test al, al
        jnz @B
        ret
CatProc endp

end start
