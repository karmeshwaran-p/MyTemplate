import pytest

create_user = True


@pytest.mark.usefixtures("testapp")
class TestLoginFlow:
    def test_login_redirect_and_session_persistence(self, testapp):
        """Tests successful login redirects and session persists across subsequent requests"""

        # 1. Post valid credentials with follow_redirects=False to verify 302 redirect location
        response = testapp.post(
            "/login",
            data=dict(email="user@example.com", password="safepassword"),
            follow_redirects=False,
        )

        assert response.status_code == 302
        assert response.location == "/"

        # 2. Follow redirect to verify successful landing page arrival and flash message
        redirect_response = testapp.get(response.location, follow_redirects=True)
        assert redirect_response.status_code == 200
        assert b"Logged in successfully." in redirect_response.data

        # 3. Subsequent request to protected route to verify session persistence
        subsequent_response = testapp.get("/dashboard/", follow_redirects=True)
        assert subsequent_response.status_code == 200
        assert b"user@example.com" in subsequent_response.data
