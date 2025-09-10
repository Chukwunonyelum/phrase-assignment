resource "aws_acm_certificate" "nginx_cert" {
  domain_name       = "phrased.online"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}




