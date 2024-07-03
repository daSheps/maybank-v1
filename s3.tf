resource "aws_s3_bucket" "web_frontend" {
  bucket = "frontend-web-mb"
  acl    = "private"

  tags = {
    Name = "frontend-web"
  }
}


resource "aws_iam_role" "cloudfront_access_role" {
  name = "cloudfront-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "cloudfront_access_policy" {
  name = "cloudfront-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.web_frontend.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudfront_access_attachment" {
  role       = aws_iam_role.cloudfront_access_role.name
  policy_arn = aws_iam_policy.cloudfront_access_policy.arn
}

resource "aws_cloudfront_origin_access_identity" "web_oai" {
  comment = "Web OAI"
}

resource "aws_s3_bucket_policy" "general_policy" {
  bucket = aws_s3_bucket.web_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "${aws_cloudfront_origin_access_identity.web_oai.iam_arn}"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.web_frontend.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "web_fe_distribution" {
  origin {
    domain_name = aws_s3_bucket.web_frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.web_frontend.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.web_frontend.id}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "web_fe_distribution"
  }
}
