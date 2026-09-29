# Partial configuration: the bucket and prefix are passed by the Makefile at init time.
terraform {
  backend "gcs" {}
}
