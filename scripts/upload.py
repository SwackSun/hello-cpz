#!/usr/bin/env python3
"""Upload a local hello-cpz IPK to the CPZ developer website as a draft."""
import argparse
from getpass import getpass
from http.cookiejar import CookieJar
import json
from pathlib import Path
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import HTTPCookieProcessor, Request, build_opener

SITE = "https://cpz.firmiss.com"


def upload(path):
    with path.open("rb") as stream:
        if stream.read(8) != b"!<arch>\n":
            raise ValueError("Expected an IPK in ar format.")
        stream.seek(0)
        client = build_opener(HTTPCookieProcessor(CookieJar()))
        with client.open(SITE + "/api/auth/csrf", timeout=30) as response:
            headers = {}
            headers["X-CSRF-Token"] = json.load(response)["csrfToken"]
        login = {"email": input("Developer email: ").strip()}
        login["password"] = getpass("Developer password: ")
        request = Request(SITE + "/api/auth/login", data=json.dumps(login).encode(),
                          headers={**headers, "Content-Type": "application/json"})
        with client.open(request, timeout=30):
            pass
        try:
            query = {"name": "hello-cpz", "category": "app"}
            offset = 0
            while True:
                with client.open(f"{SITE}/api/manage/packages?offset={offset}", timeout=30) as response:
                    items = json.load(response)
                item = next((row for row in items if row["name"] == "hello-cpz"), None)
                if item:
                    query["revision"] = item["revision"]
                    break
                if len(items) < 100:
                    break
                offset += len(items)
            request = Request(SITE + "/api/upload?" + urlencode(query), data=stream,
                              headers={**headers, "Content-Type": "application/octet-stream",
                                       "Content-Length": str(path.stat().st_size)})
            with client.open(request, timeout=120) as response:
                print(response.read().decode().strip())
        finally:
            request = Request(SITE + "/api/auth/logout", data=b"", headers=headers)
            try:
                with client.open(request, timeout=15):
                    pass
            except URLError:
                print("Session logout could not be confirmed.", file=sys.stderr)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipk", type=Path)
    try:
        upload(parser.parse_args().ipk)
    except HTTPError as error:
        sys.exit(f"Upload failed (HTTP {error.code}): {error.read(512).decode(errors='replace')}")
    except (OSError, ValueError) as error:
        sys.exit(str(error))
