// Package firebase provides a thin wrapper to initialize Firebase Admin SDK.
package firebase

import (
	"context"
	"errors"
	"os"

	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
)

// NewApp initializes a Firebase Admin app with the given project ID.
// If FIREBASE_AUTH_EMULATOR_HOST is set, it uses anonymous auth (emulator).
func NewApp(ctx context.Context, projectID string) (*firebase.App, error) {
	if projectID == "" {
		return nil, errors.New("projectID is required")
	}

	var opts []option.ClientOption
	if os.Getenv("FIREBASE_AUTH_EMULATOR_HOST") != "" {
		opts = append(opts, option.WithoutAuthentication())
	}

	return firebase.NewApp(ctx, &firebase.Config{ProjectID: projectID}, opts...)
}
