package adapterhttp

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// AuthHandler exposes authentication-related endpoints.
type AuthHandler struct{}

// NewAuthHandler constructs AuthHandler.
func NewAuthHandler() *AuthHandler {
	return &AuthHandler{}
}

// GetCurrentUser returns the authenticated user's basic profile.
func (h *AuthHandler) GetCurrentUser(c echo.Context) error {
	userID, ok := c.Get(ContextKeyUserID).(string)
	if !ok || userID == "" {
		return echo.NewHTTPError(http.StatusUnauthorized, "unauthorized")
	}
	email, _ := c.Get(ContextKeyUserEmail).(string)

	return c.JSON(http.StatusOK, map[string]string{
		"userId": userID,
		"email":  email,
	})
}
