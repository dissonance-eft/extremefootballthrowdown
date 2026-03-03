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

set GMOD="C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\hl2.exe"
set ARGS=-game garrysmod -console -sv_lan 1 +maxplayers 1 +gamemode extremefootballthrowdown +eft_nav_batch 1 +map eft_slamdunk_v6

echo Starting GMod batch nav generation...
echo Watch the console for [EFT Nav] messages.
echo GMod will quit automatically when all maps are done.
echo.

%GMOD% %ARGS%

echo.
echo Done! Copy eft_*.nav files from:
echo   %~dp0..\maps\
echo Then commit them to git and repack the workshop GMA.
pause
