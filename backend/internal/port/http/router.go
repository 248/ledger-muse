package porthttp

import "github.com/labstack/echo/v4"

// RouteRegistrar defines contract for http route registration.
type RouteRegistrar interface {
	Register(e *echo.Echo)
}
