import os


class Config:
    SESSION_ID = os.environ.get("TIKTOK_SESSION_ID", "")
    DELAY = float(os.environ.get("REMOVE_DELAY", "2.0"))
    RETRIES = int(os.environ.get("REMOVE_RETRIES", "3"))
