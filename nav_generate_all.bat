@echo off
:: ============================================================
:: EFT - Batch Nav Generation
:: ============================================================
:: Launches GMod locally, auto-cycles all 23 EFT maps,
:: generates a .nav file for each, then quits.
::
:: When done, collect nav files from:
::   garrysmod\maps\eft_*.nav
::
:: Commit them to git and include in the workshop GMA.
:: ============================================================

set GMOD="C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\gmod.exe"
set ARGS=-console -sv_lan 1 +maxplayers 1 +gamemode extremefootballthrowdown +eft_nav_batch 1 +map eft_slamdunk_v6

if not exist %GMOD% (
    echo ERROR: gmod.exe not found at %GMOD%
    echo Edit this .bat and fix the path.
    pause
    exit /b 1
)

echo Starting GMod batch nav generation...
echo Watch the console for [EFT Nav] progress messages.
echo GMod will quit automatically when all 23 maps are done.
echo.
echo Nav files will be saved to:
echo   C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\maps\eft_*.nav
echo.

%GMOD% %ARGS%

echo.
echo ============================================================
echo Done! Collect your nav files from:
echo   garrysmod\maps\eft_*.nav
echo Then: git add maps\eft_*.nav and repack the workshop GMA.
echo ============================================================
pause
