// Package health provides health check application services.
package health

import (
	"github.com/ledger-muse/backend/internal/domain/health"
)

// Service provides health check functionality.
type Service struct {
	version string
}

// NewService creates a new health check service.
func NewService(version string) *Service {
	return &Service{version: version}
}

// Status returns the current health status of the application.
func (s *Service) Status() health.Status {
	return health.Status{
		Status:  "ok",
		Version: s.version,
	}
}
