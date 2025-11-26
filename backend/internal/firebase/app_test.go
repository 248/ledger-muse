package firebase

import (
	"context"
	"testing"
)

func TestNewAppRequiresProjectID(t *testing.T) {
	t.Setenv("FIREBASE_AUTH_EMULATOR_HOST", "localhost:9099")

	_, err := NewApp(context.Background(), "")
	if err == nil {
		t.Fatalf("expected error for empty projectID")
	}
}

func TestNewAppWithEmulatorHost(t *testing.T) {
	t.Setenv("FIREBASE_AUTH_EMULATOR_HOST", "localhost:9099")

	app, err := NewApp(context.Background(), "demo-no-project")
	if err != nil {
		t.Fatalf("NewApp returned error: %v", err)
	}
	if app == nil {
		t.Fatalf("expected non-nil app")
	}
}
