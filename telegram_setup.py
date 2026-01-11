import requests
import json

# Step 1: Create bot via @BotFather in Telegram app, then paste the token here
BOT_TOKEN = '8000000000:AAGRDjUqixqTmLDCKHD5_hbLCED6OzyARpo'  # e.g., '1234567890:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

# Step 2: Create a private channel/group in Telegram, add the bot as admin, send a message, then run this script

def get_chat_id(bot_token):
    url = f'https://api.telegram.org/bot{bot_token}/getUpdates'
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        if data['ok'] and data['result']:
            # Grab the latest chat ID (from your message in the channel/group)
            latest_update = data['result'][-1]
            chat_id = latest_update['message']['chat']['id']
            print(f"Your chat_id is: {chat_id} (copy this to PS1)")
            print(f"Full webhook base: https://api.telegram.org/bot{bot_token}/sendMessage?chat_id={chat_id}&text=")
        else:
            print("No updates found. Send a message in your private channel/group first, then rerun.")
    else:
        print(f"Error: {response.status_code} - Check your bot token.")

if __name__ == '__main__':
    if BOT_TOKEN == 'YOUR_NEW_BOT_TOKEN_FROM_BOTFATHER':
        print("Replace BOT_TOKEN with your real token from @BotFather, then rerun.")
    else:

        get_chat_id(BOT_TOKEN)
