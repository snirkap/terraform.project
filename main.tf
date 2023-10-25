provider "aws" {
  region = "us-east-1"
}

# S3 bucket
resource "aws_s3_bucket" "web_surf_s3" {
  bucket = "web-surf-s3"
}

resource "aws_s3_bucket_ownership_controls" "web_surf_s3" {
  bucket = aws_s3_bucket.web_surf_s3.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "web_surf_s3" {
  bucket = aws_s3_bucket.web_surf_s3.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "web_surf_s3" {
  depends_on = [
    aws_s3_bucket_ownership_controls.web_surf_s3,
    aws_s3_bucket_public_access_block.web_surf_s3,
  ]

  bucket = aws_s3_bucket.web_surf_s3.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "web_surf_s3_policy" {
  bucket = aws_s3_bucket.web_surf_s3.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.web_surf_s3.arn}/*"
      }
    ]
  })
}

# Upload photo to S3 bucket
resource "aws_s3_object" "image_upload" {
  bucket = aws_s3_bucket.web_surf_s3.id
  key    = "rafael-leao-PzmmiWoJHA8-unsplash.jpg"
  source = "rafael-leao-PzmmiWoJHA8-unsplash.jpg"  # replace with your local image path
}

# Security groups
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow all inbound traffic on port 80"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Allow inbound traffic from ALB security group on port 80"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_s3" {
  name = "ec2-s3"
  role = aws_iam_role.ec2_s3_role.name
}



# Launch template for ASG
resource "aws_launch_template" "asg_template" {
  name_prefix   = "lt-"
  image_id      = "ami-0df435f331839b2d6"  # replace with the correct AMI ID for Amazon Linux 2023
  instance_type = "t2.micro"
  key_name      = "snir-project"

  security_group_names = [aws_security_group.instance_sg.name]

  iam_instance_profile {
    name = "${aws_iam_instance_profile.ec2_s3.name}"
  }

  user_data = base64encode(file("user_data"))
}



# ALB & Target Group
resource "aws_lb" "application_lb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  enable_deletion_protection = false

  enable_cross_zone_load_balancing   = true
  idle_timeout                       = 60
  enable_http2                       = true

  subnet_mapping {
    subnet_id     = "subnet-0c0224566e63bf9b5"
  }

  subnet_mapping {
    subnet_id     = "subnet-0a48981f36fa2dee4"
  }

}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb_target_group" "front_end" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-043038dbef4c9a40e"  # Replace with your VPC ID

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = "/"
    port                = "80"
  }
}


# ASG
resource "aws_autoscaling_group" "asg" {
  launch_template {
    id      = aws_launch_template.asg_template.id
    version = "$Latest"
  }

  min_size = 1
  max_size = 3
  desired_capacity = 2
  availability_zones = ["us-east-1a", "us-east-1b"]

  target_group_arns = [aws_lb_target_group.front_end.arn]
  
}

# CloudFront
resource "aws_cloudfront_distribution" "cloudfront_dist" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront for Surf's Up application"

  origin {
    domain_name = aws_lb.application_lb.dns_name
    origin_id   = "myOriginId"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  aliases = ["surfsupsnir.com"]

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:064195113262:certificate/266f105d-cce1-4c60-99f1-07d17eb036bd"
    ssl_support_method       = "sni-only"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "myOriginId"

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

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_All"
}

# Create a Route 53 record pointing to the CloudFront distribution
resource "aws_route53_record" "cloudfront_alias" {
  zone_id = "Z02699943I5DTUSUR4A3X"  # Replace with the actual Route 53 hosted zone ID for surfsupsnir.com
  name    = "surfsupsnir.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cloudfront_dist.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront_dist.hosted_zone_id
    evaluate_target_health= true
  }
}
