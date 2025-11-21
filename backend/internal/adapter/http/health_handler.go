// Package adapterhttp provides HTTP handlers for the application.
package adapterhttp

import (
	"net/http"

	apphealth "github.com/ledger-muse/backend/internal/application/health"

	"github.com/labstack/echo/v4"
)

// RegisterHealthRoutes registers health check routes to the Echo instance.
func RegisterHealthRoutes(e *echo.Echo, svc *apphealth.Service) {
	handler := &HealthHandler{svc: svc}
	e.GET("/health", handler.Get)
}

// HealthHandler handles health check requests.
type HealthHandler struct {
	svc *apphealth.Service
}

// Get handles GET /health requests.
// Hot reload test - ホットリロードのテスト
func (h *HealthHandler) Get(c echo.Context) error {
	status := h.svc.Status()
	return c.JSON(http.StatusOK, status)
}
