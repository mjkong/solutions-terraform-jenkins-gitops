data "terraform_remote_state" "vpc" {
  backend = "gcs"
  config = {
    bucket = "example-nonprod-devops-remote-state-bucket"
    prefix = "example/gke/vpc"
  }
}