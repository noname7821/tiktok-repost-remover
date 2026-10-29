import re
import requests


class Scraper:
    def __init__(self, session_id=""):
        self.s = requests.Session()
        self.s.headers.update({
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
        })
        if session_id:
            self.s.cookies.set("sessionid", session_id, domain=".tiktok.com")

    def get_reposts(self, username):
        url = f"https://www.tiktok.com/@{username}"
        r = self.s.get(url, timeout=15)
        html = r.text

        found = []
        for m in re.finditer(r'"id":\s*"(\d+)".*?"isRepost":\s*true', html, re.DOTALL):
            vid = m.group(1)
            found.append({
                "id": vid,
                "url": f"https://www.tiktok.com/@{username}/video/{vid}",
            })

        if not found:
            for m in re.finditer(r"/(@[\w.]+)/video/(\d+)", html):
                found.append({
                    "id": m.group(2),
                    "url": "https://www.tiktok.com" + m.group(0),
                })

        seen = set()
        out = []
        for item in found:
            if item["id"] not in seen:
                seen.add(item["id"])
                out.append(item)
        return out
