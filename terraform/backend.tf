terraform {
  backend "gcs" {
    bucket = "ledger-muse-terraform-state"
    prefix = "global"
  }
}
