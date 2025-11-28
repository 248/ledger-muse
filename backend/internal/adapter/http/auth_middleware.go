package adapterhttp

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"firebase.google.com/go/v4/auth"
	"github.com/labstack/echo/v4"
)

// Context keys for downstream handlers.
const (
	ContextKeyUserID    = "userId"
	ContextKeyUserEmail = "userEmail"
)

// TokenVerifier abstracts token verification for testability.
type TokenVerifier interface {
	VerifyIDToken(ctx context.Context, idToken string) (*auth.Token, error)
}

// FirebaseTokenVerifier implements TokenVerifier using firebase Admin SDK.
type FirebaseTokenVerifier struct {
	client *auth.Client
}

// NewFirebaseTokenVerifier constructs a TokenVerifier from firebase auth client.
func NewFirebaseTokenVerifier(client *auth.Client) *FirebaseTokenVerifier {
	return &FirebaseTokenVerifier{client: client}
}

// VerifyIDToken delegates to firebase auth client.
func (v *FirebaseTokenVerifier) VerifyIDToken(ctx context.Context, idToken string) (*auth.Token, error) {
	return v.client.VerifyIDToken(ctx, idToken)
}

// NewAuthMiddleware returns an Echo middleware that validates Authorization bearer tokens.
func NewAuthMiddleware(verifier TokenVerifier) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			authHeader := c.Request().Header.Get(echo.HeaderAuthorization)
			if authHeader == "" {
				return echo.NewHTTPError(http.StatusUnauthorized, "missing Authorization header")
			}

			parts := strings.Fields(authHeader)
			if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
				return echo.NewHTTPError(http.StatusUnauthorized, "invalid Authorization header")
			}

			idToken := parts[1]
			token, err := verifier.VerifyIDToken(c.Request().Context(), idToken)
			if err != nil {
				return echo.NewHTTPError(http.StatusUnauthorized, errors.New("invalid or expired token"))
			}

			c.Set(ContextKeyUserID, token.UID)
			if email, ok := token.Claims["email"].(string); ok && email != "" {
				c.Set(ContextKeyUserEmail, email)
			}

			return next(c)
		}
	}
}
