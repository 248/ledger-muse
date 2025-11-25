package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	adapterhttp "github.com/ledger-muse/backend/internal/adapter/http"
	apphealth "github.com/ledger-muse/backend/internal/application/health"

	"github.com/labstack/echo/v4"
)

func TestCORSPreflightAllowsAllOrigins(t *testing.T) {
	e := newServer(apphealth.NewService("test"))

	req := httptest.NewRequest(http.MethodOptions, "/health", nil)
	req.Header.Set("Origin", "http://example.com")
	req.Header.Set(echo.HeaderAccessControlRequestMethod, http.MethodGet)
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected status %d, got %d", http.StatusNoContent, rec.Code)
	}

	if got := rec.Header().Get(echo.HeaderAccessControlAllowOrigin); got != "*" {
		t.Fatalf("expected Access-Control-Allow-Origin '*', got %q", got)
	}
	if got := rec.Header().Get(echo.HeaderAccessControlAllowMethods); got == "" {
		t.Fatalf("expected Access-Control-Allow-Methods to be set")
	}
}

func TestHTTPErrorHandlerReturnsJSON(t *testing.T) {
	e := newServer(apphealth.NewService("test"))
	adapterhttp.RegisterHealthRoutes(e, apphealth.NewService("test"))

	e.GET("/boom", func(c echo.Context) error {
		return echo.NewHTTPError(http.StatusBadRequest, "bad request")
	})

	req := httptest.NewRequest(http.MethodGet, "/boom", nil)
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}

	if ct := rec.Header().Get(echo.HeaderContentType); ct == "" || ct[:16] != echo.MIMEApplicationJSON {
		t.Fatalf("expected JSON content type prefix, got %q", ct)
	}
	if body := rec.Body.String(); body == "" || body == "{}" {
		t.Fatalf("expected error body, got %q", body)
	}
}
