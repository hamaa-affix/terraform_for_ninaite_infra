//resourceの引き込み
data "aws_route53_zone" "main" {
  name         = var.domain
  private_zone = false
}

#===============================
# records
#===============================
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.sub_domain}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.assets.domain_name
    zone_id                = aws_cloudfront_distribution.assets.hosted_zone_id
    evaluate_target_health = false
  }
}
