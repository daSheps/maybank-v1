resource "aws_lb" "nlb_app" {
  name               = "app-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.private.id, aws_subnet.private_b.id]  // Specify your subnets

  enable_cross_zone_load_balancing = true
}

locals {
  origin_id = "NLBOrigin"
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  // Additional configurations as needed
}

resource "aws_lb_listener" "lb_ls" {
  load_balancer_arn = aws_lb.nlb_app.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


//CF config

resource "aws_cloudfront_distribution" "cf_app" {
  origin {
    domain_name = aws_lb.nlb_app.dns_name
    origin_id   = local.origin_id
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  // Define other CloudFront configurations as needed
}
