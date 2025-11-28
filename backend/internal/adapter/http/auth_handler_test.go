package adapterhttp_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	adapterhttp "github.com/ledger-muse/backend/internal/adapter/http"

	"firebase.google.com/go/v4/auth"
	"github.com/labstack/echo/v4"
)

func TestMeHandler_ReturnsCurrentUser(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	req.Header.Set("Authorization", "Bearer good-token")
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	mw := adapterhttp.NewAuthMiddleware(&stubVerifier{
		token: &auth.Token{UID: "user-123", Claims: map[string]interface{}{"email": "user@example.com"}},
	})

	h := adapterhttp.NewAuthHandler()

	handler := mw(h.GetCurrentUser)

	if err := handler(c); err != nil {
		t.Fatalf("handler returned error: %v", err)
	}
	if rec.Result().StatusCode != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Result().StatusCode)
	}
	var body map[string]string
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("failed to parse body: %v", err)
	}
	if body["userId"] != "user-123" || body["email"] != "user@example.com" {
		t.Fatalf("unexpected body: %+v", body)
	}
}

func TestMeHandler_RequiresAuth(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	h := adapterhttp.NewAuthHandler()
	if err := h.GetCurrentUser(c); err == nil {
		t.Fatalf("expected error when user not in context")
	}
}
