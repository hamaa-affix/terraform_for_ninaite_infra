resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.env}.${var.project}.alb.logs"

  tags = {
    Name  = var.project
    Group = var.project
  }
}

resource "aws_s3_bucket" "uploads" {
  bucket = "${var.env}.${var.project}.uploads"

  tags = {
    Name  = var.project
    Group = var.project
  }

  lifecycle_rule {
    id      = "${var.env}-${var.project}-life-cycle"
    enabled = true
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

data "aws_iam_policy_document" "uploads_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.asset_origin_access_identity.iam_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.uploads.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.asset_origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "uploads" {
  bucket = "${var.env}.${var.project}.uploads"
  policy = data.aws_iam_policy_document.uploads_policy.json
}

resource "aws_s3_bucket" "assets" {
  bucket = "${var.env}.${var.project}.assets"

  tags = {
    Name  = var.project
    Group = var.project
  }
}


data "aws_iam_policy_document" "assets_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.asset_origin_access_identity.iam_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.assets.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.asset_origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = "${var.env}.${var.project}.assets"
  policy = data.aws_iam_policy_document.assets_policy.json
