package adapterhttp

import (
	"net/http"

	apphealth "github.com/ledger-muse/backend/internal/application/health"

	"github.com/labstack/echo/v4"
)

func RegisterHealthRoutes(e *echo.Echo, svc *apphealth.Service) {
	handler := &HealthHandler{svc: svc}
	e.GET("/health", handler.Get)
}

type HealthHandler struct {
	svc *apphealth.Service
}

func (h *HealthHandler) Get(c echo.Context) error {
	status := h.svc.Status()
	return c.JSON(http.StatusOK, status)
}
