output "demo_url" {
  value = aws_lambda_function_url.this
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
  filename         = data.archive_file.this.output_path
  function_name    = "nuxt-demo"
  handler          = "index.handler"
  role             = aws_iam_role.this.arn
  source_code_hash = data.archive_file.this.output_base64sha256
  runtime          = "nodejs18.x"
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
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
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

provider "aws" {
  region = "eu-central-1"
}
