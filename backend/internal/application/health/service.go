package health

import (
	"github.com/ledger-muse/backend/internal/domain/health"
)

type Service struct {
	version string
}

func NewService(version string) *Service {
	return &Service{version: version}
}

func (s *Service) Status() health.Status {
	return health.Status{
		Status:  "ok",
		Version: s.version,
	}
}
