// Package health provides health check domain models.
package health

// Status represents the health status of the application.
type Status struct {
	Status  string `json:"status"`
	Version string `json:"version"`
}
