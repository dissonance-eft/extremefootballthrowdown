@echo off
:: ============================================================
:: EFT - Batch Nav Generation
:: ============================================================
:: OPTION A (recommended): Use this bat to launch GMod, then
:: type "eft_nav_batch_start" in the console when the map loads.
::
:: OPTION B: This bat also tries to pass +eft_nav_batch 1 as a
:: launch arg automatically (may not work on all setups).
::
:: When done, GMod quits and nav files are at:
::   garrysmod\maps\eft_*.nav
:: ============================================================

set STEAM="C:\Program Files (x86)\Steam\steam.exe"

if not exist %STEAM% (
    echo ERROR: steam.exe not found at %STEAM%
    echo Edit this .bat and fix the STEAM path.
    pause
    exit /b 1
)

echo Launching GMod via Steam with batch nav args...
echo.
echo If batch mode does NOT start automatically:
echo   1. Wait for the map to load
echo   2. Open console (~ key)
echo   3. Type: eft_nav_batch_start
echo   4. Press Enter — GMod will cycle all maps and quit when done
echo.
echo Nav files will be saved to:
echo   garrysmod\maps\eft_*.nav
echo.

%STEAM% -applaunch 4000 -console +sv_lan 1 +maxplayers 1 +gamemode extremefootballthrowdown +eft_nav_batch 1 +map eft_baseballdash_v3

echo.
echo Steam launched GMod. Watch the game console for [EFT Nav] messages.
echo GMod will quit automatically when all maps are done.
pause
