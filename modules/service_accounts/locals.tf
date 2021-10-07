locals {
  secret_arns = [for secret in [var.ca_certificate_secret, var.tfe_license_secret] : secret.arn if secret != null]
}
