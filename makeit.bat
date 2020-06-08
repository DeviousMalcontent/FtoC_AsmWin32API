@echo off

if not exist rsrc.rc goto over1
\masm32\bin\rc /v rsrc.rc
\masm32\bin\cvtres /machine:ix86 rsrc.res
 :over1
 
if exist "ftoc.obj" del "ftoc.obj"
if exist "ftoc.exe" del "ftoc.exe"

\masm32\bin\ml /c /coff "ftoc.asm"
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS "ftoc.obj" rsrc.res
 if errorlevel 1 goto errlink

dir "ftoc.*"
goto TheEnd

:nores
 \masm32\bin\Link /SUBSYSTEM:WINDOWS "ftoc.obj"
 if errorlevel 1 goto errlink
dir "ftoc.*"
goto TheEnd

:errlink
 echo _
echo Link error
goto TheEnd

:errasm
 echo _
echo Assembly Error
goto TheEnd

:TheEnd

if exist "rsrc.obj" del "rsrc.obj"
if exist "ftoc.obj" del "ftoc.obj"
if exist "ftoc.exe" ren "ftoc.exe" "FtoC_AsmWin32API.exe"
 
pause
