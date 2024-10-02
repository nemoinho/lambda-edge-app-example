output "demo_url" {
  value = aws_lambda_function_url.this
}
output "demo_url2" {
  value = aws_cloudfront_distribution.this
}

resource "aws_s3_bucket" "this" {
  // "bucket" is intentionally not set to guarantee a unique name
  tags = {
    Name = "nuxt demo"
  }
  force_destroy = true
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}


locals {
  s3_origin_id = "nuxtDemoS3Origin"
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }
  ordered_cache_behavior {
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 600
    compress               = true
    path_pattern           = "*.*"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  default_cache_behavior {
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 30
    max_ttl                = 60
    compress               = true
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.this.qualified_arn
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "nuxt-demo"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_lambda_permission" "this" {
  statement_id           = "FunctionUrlInvokePermission"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_function" "this" {
  provider         = aws.us_east_1
  filename         = data.archive_file.this.output_path
  function_name    = "nuxt-demo"
  handler          = "wrapper.handler"
  role             = aws_iam_role.this.arn
  source_code_hash = data.archive_file.this.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 5
  memory_size      = 128
  publish          = true
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = ".output/server"
  output_path = "lambda.zip"
}

resource "aws_iam_role" "this" {
  name               = "nuxt_demo"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "null_resource" "update_bucket" {
  depends_on = [
    aws_s3_bucket.this,
    data.archive_file.this,
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "aws s3 cp .output/public s3://${aws_s3_bucket.this.id}/ --recursive"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "null" {}

provider "aws" {
  region = "eu-central-1"
}
provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}
