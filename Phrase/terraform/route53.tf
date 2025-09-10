# route53.tf
data "aws_route53_zone" "primary" {
  zone_id = var.zone_id  # Your existing zone ID
}

# Create records
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "www.phrased.online"  # Correct: www + domain
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "apex" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "phrased.online"  # Root domain
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}




# resource "aws_route53_record" "www" {
#   zone_id = var.zone_id
#   name    = "www.phased.online"
#   type    = "A"
#   alias {
#     name                   = aws_lb.alb.dns_name
#     zone_id                = aws_lb.alb.zone_id
#     evaluate_target_health = true
#   }
# }

variable "zone_id" {
  description = "The ID of the Route53 hosted zone"
  type        = string
}
