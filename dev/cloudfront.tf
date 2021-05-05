#=========================================================================================================================
#オリジンアクセスアイデンティティ (OAI) と呼ばれる特別な CloudFront ユーザーを作成し、ディストリビューションに関連付けます。
#上記を作成してs３にアクセスする
#=========================================================================================================================
resource "aws_cloudfront_origin_access_identity" "asset_origin_access_identity" {
  comment = "${var.project} origin access identity for asset files"
}

resource "aws_cloudfront_distribution" "main_distribution" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "For ${var.project} Asset files(${var.env})"
  //名前解決するcnameレコード->このレコードが名前解決されてcloudfrontへアクセス
  aliases = ["www.${var.sub_domain}.${var.domain}"]

  //ssl設定
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.cdn.arn
    minimum_protocol_version       = "TLSv1.2_2018"
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  //各originサーバーの設定
  origin {
    domain_name = aws_lb.web.dns_name
    origin      = "${var.env}-${var.project}-web-alb"

    custom_origin_config {
      //originサーバーの設定
      http_port                = 80
      https_port               = 433
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 60
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  origin {
    domain_name = aws_s3_bucket.assets.bucket_domain_name
    origin_id   = "S3-${aws_s3_bucket.assets.bucket}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.asset_origin_access_identity.cloudfront_access_identity_path
    }
  }

  ordered_cache_behavior {
    path_pattern = "/public/*"
    allowed_methods = [
      "GET",
      "HEAD",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]
    target_origin_id = "S3-${aws_s3_bucket.assets.bucket}"
    compress         = true
    default_ttl      = 86400 //ttl → cache設定時間
    max_ttl          = 259200
    min_ttl          = 0
    smooth_streaming = false
    trusted_signers  = []

    viewer_protocol_policy = "redirect-to-https" //httpsでのアクセス意外はreject

    forwarded_values {
      headers = [
        "Accept",
        "Origin",
      ]
      query_string            = false
      query_string_cache_keys = []

      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }
  }

  //albのcache設定
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false
    target_origin_id       = "${var.env}-${var.project}-web-alb"
    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }



}
