#====================================
#acm for cloudfront
#====================================
resource "aws_acm_certificate" "cdn" {
  domain_name = "www.${var.sub_domain}.${var.domain}"

  subject_alternative_names = [
    "www.${var.sub_domain}.${var.domain}",
  ]

  validation_method = "DNS"
  provider          = aws.virgnia
  tags = {
    Enviroment = var.env
  }
}


resource "aws_route53_record" "cdn_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cdn.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}


resource "aws_acm_certificate_validation" "cdn" {
  provider                = aws.virgnia
  certificate_arn         = aws_acm_certificate.cdn.arn
  validation_record_fqdns = [for record in aws_route53_record.cdn_acm_validation : record.fqdn]
}

#===================================
#acm for web
#===================================
resource "aws_acm_certificate" "web" {
  domain_name = "www.${var.sub_domain}.${var.domain}"

  validation_method = "DNS"

  tags = {
    Enviroment = var.env
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.web.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "web" {
  certificate_arn         = aws_acm_certificate.web.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
