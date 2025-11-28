package adapterhttp

import "github.com/labstack/echo/v4"

// RegisterAuthRoutes wires authentication-protected routes.
func RegisterAuthRoutes(e *echo.Echo, verifier TokenVerifier) {
	mw := NewAuthMiddleware(verifier)
	handler := NewAuthHandler()

	protected := e.Group("/api/v1", mw)
	protected.GET("/me", handler.GetCurrentUser)
}
