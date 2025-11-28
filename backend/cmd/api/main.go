// Package main is the entry point for the Ledger Muse API server.
package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	adapterhttp "github.com/ledger-muse/backend/internal/adapter/http"
	apphealth "github.com/ledger-muse/backend/internal/application/health"
	firebaseapp "github.com/ledger-muse/backend/internal/firebase"
	"github.com/ledger-muse/backend/pkg/version"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	ctx := context.Background()
	healthService := apphealth.NewService(version.Version)

	authVerifier, err := buildAuthVerifier(ctx)
	if err != nil {
		log.Fatalf("failed to initialize auth verifier: %v", err)
	}

	e := newServer(healthService, authVerifier)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	go func() {
		if err := e.Start(":" + port); err != nil && err != http.ErrServerClosed {
			e.Logger.Fatalf("server error: %v", err)
		}
	}()

	gracefulShutdown(e)
}

func gracefulShutdown(e *echo.Echo) {
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := e.Shutdown(ctx); err != nil {
		log.Printf("graceful shutdown error: %v", err)
	}
}

func newServer(healthService *apphealth.Service, authVerifier adapterhttp.TokenVerifier) *echo.Echo {
	e := echo.New()
	e.HideBanner = true

	e.Pre(middleware.RemoveTrailingSlash())
	e.Use(middleware.Recover())
	e.Use(middleware.Logger())
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{"*"},
		AllowMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodDelete,
			http.MethodOptions,
		},
		AllowHeaders: []string{
			echo.HeaderContentType,
			echo.HeaderAuthorization,
			echo.HeaderAccept,
		},
	}))

	e.HTTPErrorHandler = func(err error, c echo.Context) {
		var (
			he     *echo.HTTPError
			status = http.StatusInternalServerError
			msg    = http.StatusText(http.StatusInternalServerError)
		)

		if errors.As(err, &he) {
			status = he.Code
			switch val := he.Message.(type) {
			case string:
				msg = val
			case error:
				msg = val.Error()
			default:
				msg = http.StatusText(status)
			}
		} else if err != nil {
			msg = err.Error()
		}

		if !c.Response().Committed {
			if err := c.JSON(status, map[string]string{"message": msg}); err != nil {
				c.Logger().Error(err)
			}
		}
	}

	adapterhttp.RegisterHealthRoutes(e, healthService)
	adapterhttp.RegisterAuthRoutes(e, authVerifier)
	return e
}

func buildAuthVerifier(ctx context.Context) (adapterhttp.TokenVerifier, error) {
	projectID := os.Getenv("FIREBASE_PROJECT_ID")
	if projectID == "" {
		return nil, fmt.Errorf("FIREBASE_PROJECT_ID environment variable must be set")
	}
	app, err := firebaseapp.NewApp(ctx, projectID)
	if err != nil {
		return nil, err
	}
	client, err := app.Auth(ctx)
	if err != nil {
		return nil, err
	}
	return adapterhttp.NewFirebaseTokenVerifier(client), nil
}
