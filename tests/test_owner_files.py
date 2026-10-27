import re
import time

import requests
from openhost_test_harness import OpenhostStack
from playwright.sync_api import Page
from playwright.sync_api import expect

XHR = {"X-Requested-With": "XmlHttpRequest"}


def _wait_for_app(stack: OpenhostStack) -> None:
    deadline = time.monotonic() + 60
    while True:
        try:
            response = stack.owner_session.get(f"{stack.url}/api/config", headers=XHR, timeout=30)
            if response.status_code == 200 or time.monotonic() > deadline:
                break
        except requests.ConnectionError:
            if time.monotonic() > deadline:
                raise
        time.sleep(2)
    assert response.status_code == 200, (
        f"/api/config: {response.status_code}: {response.text[:500]}\n\napp logs:\n{stack.app_logs()[-5000:]}"
    )


def test_owner_lands_in_zone_files_without_a_login_form(stack: OpenhostStack, page: Page) -> None:
    _wait_for_app(stack)
    # A file in an app data dir: Filestash's root is the zone's data (all apps), so the owner can browse to it.
    marker = "upstream-coverage-marker.txt"
    (stack.data_dir / marker).write_text("hello\n")

    stack.playwright_login(page)
    page.goto(stack.url)
    # The passthrough identity provider signs the owner straight into the "Files" backend: no Filestash login page.
    expect(page).to_have_url(re.compile(r"/files/"), timeout=60_000)
    expect(page.get_by_role("link", name="directory app_data", exact=True)).to_be_visible(timeout=30_000)
    expect(page.locator("input[type=password]")).to_have_count(0)

    page.goto(f"{stack.url}/files/app_data/{stack.manifest.name}/")
    expect(page.get_by_text(marker, exact=True).first).to_be_visible(timeout=30_000)


def test_sharing_is_disabled(stack: OpenhostStack) -> None:
    _wait_for_app(stack)
    config = stack.owner_session.get(f"{stack.url}/api/config", headers=XHR, timeout=30).json()["result"]
    assert config["enable_share"] is False, f"share links are enabled: {config}"
