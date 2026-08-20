import threading
import pytest
from werkzeug.serving import make_server
from playwright.sync_api import Page, expect

from appname import create_app
from appname.models import db
from appname.models.user import User


@pytest.fixture(scope="module")
def live_server_url():
    """
    Starts a live Flask test server in a background thread for Playwright E2E tests.
    This pattern ensures the test is completely self-contained and does not require
    manually starting a external dev server process.
    """
    app = create_app("appname.settings.TestConfig")

    with app.app_context():
        db.create_all()
        admin = User("admin@example.com", "supersafepassword", admin=True)
        user = User("user@example.com", "safepassword")
        db.session.add_all([admin, user])
        db.session.commit()

    server = make_server("127.0.0.1", 5001, app)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

    yield "http://127.0.0.1:5001"

    server.shutdown()
    thread.join()


def test_login_ui_success(page: Page, live_server_url):
    """E2E test verifying successful UI login flow and landing on dashboard"""
    # 1. Navigate to the login page in a real browser
    page.goto(f"{live_server_url}/login")

    # 2. Fill in valid credentials
    page.fill("input[name='email']", "user@example.com")
    page.fill("input[name='password']", "safepassword")

    # 3. Submit the login form
    page.click("button[type='submit']")

    # 4. Assert the browser lands on dashboard and DOM element confirms login succeeded
    expect(page.locator("body")).to_contain_text("user@example.com")
