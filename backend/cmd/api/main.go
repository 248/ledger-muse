package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	adapterhttp "github.com/ledger-muse/backend/internal/adapter/http"
	apphealth "github.com/ledger-muse/backend/internal/application/health"
	"github.com/ledger-muse/backend/pkg/version"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	e := echo.New()
	e.HideBanner = true
	e.Use(middleware.Recover())
	e.Pre(middleware.RemoveTrailingSlash())

	healthService := apphealth.NewService(version.Version)
	adapterhttp.RegisterHealthRoutes(e, healthService)

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
