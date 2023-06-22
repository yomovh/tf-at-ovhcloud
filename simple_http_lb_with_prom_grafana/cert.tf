resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.acme_email_address
}

resource "acme_certificate" "cert" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "${var.dns_subdomain}.${var.dns_zone}"
  disable_complete_propagation = var.acme_disable_complete_propagation

  dns_challenge {
    provider = "ovh"
  }
}

resource "openstack_keymanager_secret_v1" "tls_secret" {
  name = "${var.resource_prefix}tls_secret" 
  payload_content_type     = "application/octet-stream"
  payload_content_encoding = "base64"
  payload = acme_certificate.cert.certificate_p12
}
