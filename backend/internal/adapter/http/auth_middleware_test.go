package adapterhttp_test

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	adapterhttp "github.com/ledger-muse/backend/internal/adapter/http"

	"firebase.google.com/go/v4/auth"
	"github.com/labstack/echo/v4"
)

type stubVerifier struct {
	token *auth.Token
	err   error
}

func (s *stubVerifier) VerifyIDToken(ctx context.Context, idToken string) (*auth.Token, error) {
	return s.token, s.err
}

func TestAuthMiddleware_AllowsValidToken(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	req.Header.Set("Authorization", "Bearer good-token")
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	mw := adapterhttp.NewAuthMiddleware(&stubVerifier{
		token: &auth.Token{UID: "user-123", Claims: map[string]interface{}{"email": "user@example.com"}},
	})

	nextCalled := false
	handler := mw(func(c echo.Context) error {
		nextCalled = true
		if got := c.Get(adapterhttp.ContextKeyUserID); got != "user-123" {
			t.Fatalf("expected userID in context, got %v", got)
		}
		if got := c.Get(adapterhttp.ContextKeyUserEmail); got != "user@example.com" {
			t.Fatalf("expected email in context, got %v", got)
		}
		return c.NoContent(http.StatusOK)
	})

	if err := handler(c); err != nil {
		t.Fatalf("handler returned error: %v", err)
	}
	if rec.Result().StatusCode != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Result().StatusCode)
	}
	if !nextCalled {
		t.Fatalf("expected next handler to be called")
	}
}

func TestAuthMiddleware_RejectsMissingHeader(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	mw := adapterhttp.NewAuthMiddleware(&stubVerifier{})
	handler := mw(func(c echo.Context) error { return c.NoContent(http.StatusOK) })

	err := handler(c)
	httpErr, ok := err.(*echo.HTTPError)
	if !ok {
		t.Fatalf("expected HTTPError, got %v", err)
	}
	if httpErr.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", httpErr.Code)
	}
}

func TestAuthMiddleware_RejectsInvalidPrefix(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	req.Header.Set("Authorization", "Token something")
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	mw := adapterhttp.NewAuthMiddleware(&stubVerifier{})
	handler := mw(func(c echo.Context) error { return c.NoContent(http.StatusOK) })

	err := handler(c)
	httpErr, ok := err.(*echo.HTTPError)
	if !ok {
		t.Fatalf("expected HTTPError, got %v", err)
	}
	if httpErr.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", httpErr.Code)
	}
}

func TestAuthMiddleware_RejectsWhenVerifierFails(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	req.Header.Set("Authorization", "Bearer bad-token")
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	mw := adapterhttp.NewAuthMiddleware(&stubVerifier{
		err: errors.New("invalid token"),
	})
	handler := mw(func(c echo.Context) error { return c.NoContent(http.StatusOK) })

	err := handler(c)
	httpErr, ok := err.(*echo.HTTPError)
	if !ok {
		t.Fatalf("expected HTTPError, got %v", err)
	}
	if httpErr.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", httpErr.Code)
	}
}
