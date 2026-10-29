import sys
from config import Config
from scraper import Scraper
from remover import Remover


def main():
    cfg = Config()
    scraper = Scraper(cfg.SESSION_ID)
    remover = Remover(cfg.SESSION_ID)

    username = input("username: ").strip()
    if not username:
        print("no username")
        return 1

    print("scanning...")
    reposts = scraper.get_reposts(username)
    print("found", len(reposts))

    if not reposts:
        print("nothing to do")
        return 0

    c = input(f"remove {len(reposts)}? (y/n): ").strip().lower()
    if c != "y":
        print("aborted")
        return 0

    n = remover.remove(reposts, delay=cfg.DELAY)
    print("removed", n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
