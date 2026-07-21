from curl_cffi import requests
import json
from datetime import datetime, timedelta

def fetch_corrected_schedule():
    print("Fetching and correcting schedule times...")
    
    today_str = datetime.now().strftime("%Y-%m-%d")
    
    channels = [
        {"id": "TV50", "name": "Channel 9"},
        {"id": "CH34", "name": "Channel 12"},
        {"id": "CH36", "name": "Channel 13"},
        {"id": "PT92", "name": "Channel 14"}
    ]
    
    all_programs = []
    
    headers = {
        "accept": "*/*",
        "accept-language": "he-IL",
        "origin": "https://www.yes.co.il",
        "referer": "https://www.yes.co.il/",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"
    }
    
    session = requests.Session(impersonate="chrome110")
    
    for ch in channels:
        url = f"https://svc.yes.co.il/api/content/broadcast-schedule/channels/{ch['id']}?date={today_str}&ignorePastItems=true"
        
        try:
            response = session.get(url, headers=headers)
            if response.status_code == 200:
                data = response.json()
                if "items" in data:
                    for item in data["items"]:
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
        except Exception as e:
            print(f"Error fetching {ch['name']}: {e}")

    # Sort programs chronologically by start time
    all_programs.sort(key=lambda x: x.get("starts", ""))

    # Save to tv_guide.json
    output_path = '../grandma_tv_app/assets/tv_guide.json'
    final_data = {"items": all_programs}
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(final_data, f, ensure_ascii=False, indent=4)
        
    print(f"\n--- Success! ---")
    print(f"Saved {len(all_programs)} programs with corrected local times into 'tv_guide.json'.")

if __name__ == "__main__":
    fetch_corrected_schedule()