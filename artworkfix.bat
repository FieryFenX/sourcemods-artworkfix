@echo off
setlocal enabledelayedexpansion

:: --- STEP 1: Navigate to mods directory and collect mod names ---
:: Define root directory and navigate up to Steam folder
set "rootDir=%~dp0"
set "currentDir=%rootDir%"
for /l %%i in (1,1,4) do (
    set "currentDir=!currentDir!\.."
)
cd /d "!currentDir!" || (echo Failed to navigate up && pause && goto :eof)

:: Define mods directory
set "modsDir=%cd%\steamapps\sourcemods"
cd /d "%modsDir%" || (echo Failed to change to mods directory && pause && goto :eof)

:: Open file to store mod names
set "outputFile=%rootDir%mod_names.txt"
echo Mods from sourcemods: > "%outputFile%"

:: Collect mod names
set /a modIndex=0
for /d %%d in (*) do (
    if exist "%%d\gameinfo.txt" (
        for /f "usebackq tokens=1,* delims=	 " %%g in ("%%d\gameinfo.txt") do (
            if /i "%%g"=="game" (
                set "line=%%h"
                set "firstchar=!line:~0,1!"
                if !firstchar!==^" if !line:~-1!==^" (
                    set /a modIndex+=1
                    echo !modIndex!. !line! >> "%outputFile%"
                    set "mod[!modIndex!]=!line!"
                )
            )
        )
    )
)

:: Output mod names to user
echo.
type "%outputFile%"
echo.

:: --- STEP 2: Ask user for the latest mod ---
set /a numFiles=%modIndex%-1
set /p userChoice="Which mod was the latest added? Enter a number (1-%modIndex%): "

if not defined userChoice (echo Invalid input. Exiting... && pause && goto :eof)
if %userChoice% lss 1 (echo Invalid number. Exiting... && pause && goto :eof)
if %userChoice% gtr %modIndex% (echo Invalid number. Exiting... && pause && goto :eof)

:: --- STEP 3: Process file numbers ---
cd /d "%rootDir%"
set "searchString=214748"

:: Collect all files with the search string in reverse order
dir /b *%searchString%* /o-n > temp_files_reverse.txt

:: Create planned renames file
set "plannedFile=%rootDir%planned_rename.txt"

set /a userIndex=3648+%userChoice%

:: Process files in reverse order
for /f "delims=" %%f in (temp_files_reverse.txt) do (
    set "currentFile=%%f"
    set "filename=%%~nf"
    set "extension=%%~xf"
    set "baseNum=!filename:~0,10!"
    
    :: Compare the number part to determine if this file needs to be renamed
    set "numPart=!baseNum:~6,4!"
    if !numPart! geq %userIndex% (
        set "prefix=!baseNum:~0,6!"
        set /a "newSuffix=numPart + 1"
        set "newSuffix=0000!newSuffix!"
        set "newSuffix=!newSuffix:~-4!"
        set "newName=!prefix!!newSuffix!!currentFile:~10!"
        echo Rename: !currentFile! -^> !newName! >> "%plannedFile%"
	rename "!currentFile!" "!newName!"
    )
)

:: Output results
echo --- Completed renames ---
type "%plannedFile%"
echo ------------------------

del planned_rename.txt 2>nul
del mod_names.txt 2>nul
del temp_files_reverse.txt 2>nul

:end
endlocal
pause