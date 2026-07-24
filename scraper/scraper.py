from curl_cffi import requests
import json
from datetime import datetime, timedelta
import time # Added for the delay mechanism

def fetch_corrected_schedule():
    print("Fetching schedule for requested channel ranges (1-25, 180-188)...")
    
    today_str = datetime.now().strftime("%Y-%m-%d")
    
    # List of all requested channels. 
    # TODO: Replace 'FILL_ID_HERE' with the actual yes.co.il internal ID for each channel.
    channels = [
        # --- Channels 1 to 25 ---
        {"id": "YSA1", "name": "Channel 1"},
        {"id": "YSA2", "name": "Channel 2"},
        {"id": "YSA3", "name": "Channel 3"},
        {"id": "YSAU", "name": "Channel 4"},
        {"id": "YS19", "name": "Channel 5"},
        {"id": "YS20", "name": "Channel 6"},
        {"id": "YS22", "name": "Channel 7"},
        {"id": "YSAT", "name": "Channel 8"},
        # ... Add channels 3 to 8 here using the same format ...
        {"id": "TV50", "name": "Channel 9"},
        {"id": "FILL_ID_HERE", "name": "Channel 10"},
        {"id": "CH30", "name": "Channel 11"},
        {"id": "CH34", "name": "Channel 12"},
        {"id": "CH36", "name": "Channel 13"},
        {"id": "PT92", "name": "Channel 14"},
        {"id": "CN28", "name": "Channel 15"},
        {"id": "CH65", "name": "Channel 22"},
        # ... Add channels 16 to 22 here using the same format ...
        
        # --- Channels 180 to 188 ---
        {"id": "TV81", "name": "Channel 181"},
        {"id": "TV82", "name": "Channel 182"},
        {"id": "CN03", "name": "Channel 183"},
        {"id": "TV85", "name": "Channel 184"},
        {"id": "CH24", "name": "Channel 185"},
        {"id": "PT73", "name": "Channel 186"},
        {"id": "PT74", "name": "Channel 187"},
        {"id": "CH76", "name": "Channel 188"},
        {"id": "PT51", "name": "Channel 191"},
        {"id": "TV60", "name": "Channel 192"},
        {"id": "PT45", "name": "Channel 195"},
        # ... Add channels 181 to 195 here using the same format ...
    ]
    
    all_programs = []
    
    headers = {
        "accept": "*/*",
        "accept-language": "he-IL",
        "origin": "https://www.yes.co.il",
        "referer": "https://www.yes.co.il/",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
    }
    
    session = requests.Session(impersonate="chrome110")
    
    for ch in channels:
        # Skip placeholders so the script doesn't crash before you fill them in
        if ch['id'] == "FILL_ID_HERE":
            continue
            
        url = f"https://svc.yes.co.il/api/content/broadcast-schedule/channels/{ch['id']}?date={today_str}&ignorePastItems=true"
        
        try:
            response = session.get(url, headers=headers)
            print(f"[{ch['name']}] Status Code: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                if "items" in data:
                    for item in data["items"]:
                        # Inject the channel ID so the Flutter app knows which channel this program belongs to
                        item["channelId"] = ch["id"]
                        
                        # Convert UTC string times to local Israel time (+3 hours)
                        if "starts" in item and item["starts"]:
                            dt_start = datetime.strptime(item["starts"], "%Y-%m-%dT%H:%M:%SZ") + timedelta(hours=3)
                            item["starts_local"] = dt_start.strftime("%H:%M")
                            item["starts"] = dt_start.isoformat()
                            
                        if "ends" in item and item["ends"]:
                            dt_end = datetime.strptime(item["ends"], "%Y-%m-%dT%H:%M:%SZ") + timedelta(hours=3)
                            item["ends_local"] = dt_end.strftime("%H:%M")
                            item["ends"] = dt_end.isoformat()
                            
                        all_programs.append(item)
            else:
                print(f"Failed to fetch {ch['name']}. Response: {response.text[:100]}")
                
        except Exception as e:
            print(f"Error fetching {ch['name']}: {e}")
            
        # Critical sleep mechanism (0.5 seconds) to prevent IP ban from yes.co.il servers
        time.sleep(0.5)

    # Sort all collected programs chronologically by start time
    all_programs.sort(key=lambda x: x.get("starts", ""))

    # Save to tv_guide.json in the Flutter app's assets folder
    output_path = '../grandma_tv_app/assets/tv_guide.json'
    final_data = {"items": all_programs}
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(final_data, f, ensure_ascii=False, indent=4)
        
    print(f"\n--- Success! ---")
    print(f"Saved {len(all_programs)} programs into 'tv_guide.json'.")

if __name__ == "__main__":
    fetch_corrected_schedule()