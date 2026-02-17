-- gamemode/sv_security.lua
/// MANIFEST LINKS:
/// Principles: P-010 (Sport Identity - Anti-Cheat/Exploit)
-- Backdoor / Malicious Code Scanner for EFT
-- Embedded console command that scans Lua files for suspicious patterns.
--
-- Usage:
--   eft_scan              — Scan the gamemode and all addons
--   eft_scan gamemode     — Scan only the gamemode
--   eft_scan addons       — Scan only addons
--   eft_scan <addonname>  — Scan a specific addon
--
-- This is a development/admin tool. It checks for:
--   - CompileString / RunString (dynamic code execution)
--   - HTTP/http.Fetch/Post fetching and executing code
--   - BroadcastLua with dynamic content
--   - Obfuscated strings (long hex/base64, \x escapes)
--   - Backdoor-specific patterns (timer.Create with HTTP, concommand backdoors)
--   - Suspicious file operations (writing .lua files)
--   - Known backdoor signatures

if not SERVER then return end

-- ============================================================================
-- PATTERN DEFINITIONS
-- ============================================================================

---@class ScanPattern
---@field pattern string Lua pattern to match
---@field severity string "critical"|"warning"|"info"
---@field description string What this pattern indicates
---@field falsePositiveHint? string When this might be a false positive

local SCAN_PATTERNS = {
    -- CRITICAL: Direct code execution from strings
    {
        pattern = "CompileString%s*%(",
        severity = "critical",
        description = "CompileString() - compiles and potentially executes arbitrary Lua code",
        falsePositiveHint = "OK if compiling known/static strings, dangerous if input comes from network/HTTP",
    },
    {
        pattern = "RunString%s*%(",
        severity = "critical",
        description = "RunString() - executes arbitrary Lua code from a string",
        falsePositiveHint = "Almost always dangerous. Legitimate uses are extremely rare.",
    },
    {
        pattern = "RunStringEx%s*%(",
        severity = "critical",
        description = "RunStringEx() - executes arbitrary Lua code with custom identifier",
    },
    {
        pattern = "CompileFile%s*%(",
        severity = "warning",
        description = "CompileFile() - compiles a Lua file dynamically",
        falsePositiveHint = "OK for legitimate module loading, suspicious if path comes from user input",
    },

    -- CRITICAL: HTTP + execution combos
    {
        pattern = "http%.Fetch%s*%(.-RunString",
        severity = "critical",
        description = "HTTP fetch followed by RunString - classic backdoor pattern",
    },
    {
        pattern = "http%.Fetch%s*%(.-CompileString",
        severity = "critical",
        description = "HTTP fetch followed by CompileString - classic backdoor pattern",
    },
    {
        pattern = "HTTP%s*%(%s*{.-url.-}%s*%)",
        severity = "warning",
        description = "HTTP() request - check if the response is being executed as code",
        falsePositiveHint = "OK for APIs/data fetching, dangerous if response is run as Lua",
    },

    -- CRITICAL: BroadcastLua with dynamic content
    {
        pattern = 'BroadcastLua%s*%(%s*[^"\']+%)',
        severity = "warning",
        description = "BroadcastLua() with non-literal string - could execute arbitrary client code",
        falsePositiveHint = "OK if concatenating known safe values like entity indices",
    },

    -- WARNING: Obfuscation indicators
    {
        pattern = "\\x%x%x\\x%x%x\\x%x%x\\x%x%x",
        severity = "warning",
        description = "Hex-escaped string sequence - possible obfuscation",
        falsePositiveHint = "Could be binary data or legitimate encoding",
    },
    {
        pattern = "string%.char%s*%(.-%d+.-%d+.-%d+.-%d+.-%d+",
        severity = "warning",
        description = "string.char() with many numeric args - possible obfuscated string",
    },
    {
        pattern = "util%.Decompress%s*%(",
        severity = "warning",
        description = "util.Decompress() - could be unpacking obfuscated code",
        falsePositiveHint = "OK for legitimate data decompression",
    },

    -- WARNING: Suspicious file operations
    {
        pattern = "file%.Write%s*%(.-%.lua",
        severity = "warning",
        description = "Writing .lua files - could be installing persistent backdoor",
    },
    {
        pattern = "file%.Append%s*%(.-%.lua",
        severity = "warning",
        description = "Appending to .lua files - could be injecting code",
    },

    -- WARNING: Suspicious networking
    {
        pattern = "concommand%.Add%s*%(.-RunString",
        severity = "critical",
        description = "Console command that runs arbitrary strings - backdoor pattern",
    },
    {
        pattern = "concommand%.Add%s*%(.-CompileString",
        severity = "critical",
        description = "Console command that compiles arbitrary strings - backdoor pattern",
    },
    {
        pattern = "net%.Receive%s*%(.-RunString",
        severity = "critical",
        description = "Net receive handler that runs arbitrary strings - backdoor pattern",
    },

    -- WARNING: Timer-based persistence
    {
        pattern = "timer%.Create%s*%(.-http%.Fetch",
        severity = "critical",
        description = "Timer that periodically fetches from HTTP - persistent backdoor pattern",
    },
    {
        pattern = "timer%.Create%s*%(.-http%.Post",
        severity = "critical",
        description = "Timer that periodically posts to HTTP - data exfiltration pattern",
    },

    -- INFO: Things to review
    {
        pattern = "debug%.getinfo%s*%(",
        severity = "info",
        description = "debug.getinfo() - can be used to inspect/bypass security",
    },
    {
        pattern = "debug%.sethook%s*%(",
        severity = "warning",
        description = "debug.sethook() - can intercept function calls",
    },
    {
        pattern = "debug%.setfenv%s*%(",
        severity = "warning",
        description = "debug.setfenv() - can modify function environments",
    },
    {
        pattern = "setfenv%s*%(",
        severity = "warning",
        description = "setfenv() - can modify function environments for sandbox escape",
    },
    {
        pattern = "_G%[.-%]%s*=",
        severity = "info",
        description = "Dynamic global assignment - could be overwriting critical functions",
        falsePositiveHint = "Often legitimate, but review what's being overwritten",
    },

    -- Known backdoor domains / signatures
    {
        pattern = "pastebin%.com/raw",
        severity = "critical",
        description = "Pastebin raw URL - extremely common backdoor source",
    },
    {
        pattern = "hastebin%.com/raw",
        severity = "critical",
        description = "Hastebin raw URL - common backdoor source",
    },
    {
        pattern = "githubusercontent%.com",
        severity = "info",
        description = "GitHub raw content URL - review what's being fetched",
        falsePositiveHint = "Often legitimate for auto-updaters",
    },
    {
        pattern = "gmodstore%.com",
        severity = "info",
        description = "GmodStore URL - likely license/DRM check",
    },
}

-- ============================================================================
-- SCANNER
-- ============================================================================

local COLOR_CRIT = "\x1b[91m"    -- Red
local COLOR_WARN = "\x1b[93m"    -- Yellow
local COLOR_INFO = "\x1b[96m"    -- Cyan
local COLOR_OK   = "\x1b[92m"    -- Green
local COLOR_RST  = "\x1b[0m"     -- Reset

local severityColors = {
    critical = COLOR_CRIT,
    warning = COLOR_WARN,
    info = COLOR_INFO,
}

local severityLabels = {
    critical = "CRITICAL",
    warning  = "WARNING",
    info     = "INFO",
}

--- Scan a single file for suspicious patterns.
---@param filePath string Path relative to GarrysMod/garrysmod/
---@param results table Accumulator for findings
local function ScanFile(filePath, results)
    local content = file.Read(filePath, "GAME")
    if not content then return end

    local lines = string.Explode("\n", content)

    for lineNum, line in ipairs(lines) do
        -- Skip comment-only lines
        local trimmed = string.TrimLeft(line)
        if trimmed:sub(1, 2) == "--" then continue end
        -- Skip lines inside block comments (simple heuristic)
        if trimmed:sub(1, 4) == "--[[" then continue end

        for _, pat in ipairs(SCAN_PATTERNS) do
            if line:find(pat.pattern) then
                results[#results + 1] = {
                    file = filePath,
                    line = lineNum,
                    severity = pat.severity,
                    description = pat.description,
                    hint = pat.falsePositiveHint,
                    content = string.TrimLeft(line):sub(1, 120), -- Truncate long lines
                }
            end
        end
    end
end

--- Recursively scan all .lua files in a directory.
---@param dir string Directory path relative to GarrysMod/garrysmod/
---@param results table Accumulator
---@param fileCount table {n = 0} counter
local function ScanDirectory(dir, results, fileCount)
    local files, dirs = file.Find(dir .. "/*", "GAME")

    for _, f in ipairs(files or {}) do
        if f:sub(-4) == ".lua" then
            fileCount.n = fileCount.n + 1
            ScanFile(dir .. "/" .. f, results)
        end
    end

    for _, d in ipairs(dirs or {}) do
        ScanDirectory(dir .. "/" .. d, results, fileCount)
    end
end

--- Print scan results to console.
---@param results table Array of findings
---@param fileCount number Total files scanned
---@param scope string What was scanned
local function PrintResults(results, fileCount, scope)
    print("")
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║              EFT SECURITY SCANNER RESULTS                  ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print(string.format("  Scope: %s", scope))
    print(string.format("  Files scanned: %d", fileCount))
    print(string.format("  Findings: %d", #results))
    print("")

    if #results == 0 then
        print("  ✓ No suspicious patterns found. All clear!")
        print("")
        return
    end

    -- Sort by severity (critical first)
    local severityOrder = { critical = 1, warning = 2, info = 3 }
    table.sort(results, function(a, b)
        local sa = severityOrder[a.severity] or 99
        local sb = severityOrder[b.severity] or 99
        if sa ~= sb then return sa < sb end
        return a.file < b.file
    end)

    -- Count by severity
    local counts = { critical = 0, warning = 0, info = 0 }
    for _, r in ipairs(results) do
        counts[r.severity] = (counts[r.severity] or 0) + 1
    end

    if counts.critical > 0 then
        print(string.format("  [!] CRITICAL: %d findings", counts.critical))
    end
    if counts.warning > 0 then
        print(string.format("  [?] WARNING:  %d findings", counts.warning))
    end
    if counts.info > 0 then
        print(string.format("  [i] INFO:     %d findings", counts.info))
    end
    print("")
    print(string.rep("-", 70))

    local currentFile = ""
    for _, r in ipairs(results) do
        if r.file ~= currentFile then
            currentFile = r.file
            print("")
            print("  " .. currentFile)
        end

        local label = severityLabels[r.severity] or "???"
        print(string.format("    [%s] Line %d: %s", label, r.line, r.description))
        print(string.format("      > %s", r.content))
        if r.hint then
            print(string.format("      Note: %s", r.hint))
        end
    end

    print("")
    print(string.rep("-", 70))

    if counts.critical > 0 then
        print("")
        print("  *** CRITICAL findings require immediate review! ***")
        print("  These patterns are commonly used in backdoors and malicious code.")
        print("  If you did not intentionally add this code, your server may be compromised.")
    end

    print("")
end

-- ============================================================================
-- CONSOLE COMMAND
-- ============================================================================

concommand.Add("eft_scan", function(ply, cmd, args)
    -- Admin-only (or server console)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[EFT Security] This command requires superadmin access.\n")
        return
    end

    local scope = args[1] or "all"
    local results = {}
    local fileCount = { n = 0 }
    local scopeDesc = ""

    if scope == "gamemode" then
        scopeDesc = "Gamemode only"
        local gmPath = GAMEMODE and GAMEMODE.Folder or "gamemodes/extremefootballthrowdown"
        ScanDirectory(gmPath, results, fileCount)

    elseif scope == "addons" then
        scopeDesc = "All addons"
        local _, addonDirs = file.Find("addons/*", "GAME")
        for _, addonDir in ipairs(addonDirs or {}) do
            ScanDirectory("addons/" .. addonDir, results, fileCount)
        end

    elseif scope == "all" then
        scopeDesc = "Gamemode + All addons"
        local gmPath = GAMEMODE and GAMEMODE.Folder or "gamemodes/extremefootballthrowdown"
        ScanDirectory(gmPath, results, fileCount)

        local _, addonDirs = file.Find("addons/*", "GAME")
        for _, addonDir in ipairs(addonDirs or {}) do
            ScanDirectory("addons/" .. addonDir, results, fileCount)
        end

    else
        -- Scan specific addon
        scopeDesc = "Addon: " .. scope
        if file.IsDir("addons/" .. scope, "GAME") then
            ScanDirectory("addons/" .. scope, results, fileCount)
        else
            print("[EFT Security] Addon '" .. scope .. "' not found in addons/")
            return
        end
    end

    PrintResults(results, fileCount.n, scopeDesc)
end, nil, "Scan Lua files for backdoors and suspicious patterns. Usage: eft_scan [gamemode|addons|all|<addonname>]")

-- Auto-scan on server start is disabled by default to avoid load-time lag.
-- Run 'eft_scan' manually in console when you want to check for issues.
-- To re-enable auto-scan, set eft_security_autoscan to 1.
if not ConVarExists("eft_security_autoscan") then
    CreateConVar("eft_security_autoscan", "0", FCVAR_ARCHIVE, "Run security scan automatically on server start")
end

hook.Add("Initialize", "EFT_SecurityQuickScan", function()
    if not GetConVar("eft_security_autoscan"):GetBool() then return end

    timer.Simple(5, function()
        local results = {}
        local fileCount = { n = 0 }
        local gmPath = GAMEMODE and GAMEMODE.Folder or "gamemodes/extremefootballthrowdown"
        ScanDirectory(gmPath, results, fileCount)

        local criticals = 0
        for _, r in ipairs(results) do
            if r.severity == "critical" then
                criticals = criticals + 1
            end
        end

        if criticals > 0 then
            print("")
            print("[EFT Security] WARNING: " .. criticals .. " CRITICAL finding(s) detected in gamemode!")
            print("[EFT Security] Run 'eft_scan gamemode' in console for full report.")
            print("")
        else
            MsgN("[EFT Security] Quick scan: " .. fileCount.n .. " files clean.")
        end
    end)
end)
