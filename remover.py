import time
import requests


class Remover:
    def __init__(self, session_id=""):
        self.s = requests.Session()
        self.s.headers.update({
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            "Referer": "https://www.tiktok.com/",
        })
        if session_id:
            self.s.cookies.set("sessionid", session_id, domain=".tiktok.com")

    def remove(self, reposts, delay=2.0):
        removed = 0
        for item in reposts:
            try:
                r = self.s.post(
                    "https://www.tiktok.com/api/video/remove/",
                    data={"video_id": item["id"]},
                    timeout=10,
                )
                if r.status_code == 200:
                    print("removed", item["id"])
                    removed += 1
                else:
                    print("failed", item["id"], r.status_code)
            except Exception as e:
                print("error", item["id"], e)
            time.sleep(delay)
        return removed
