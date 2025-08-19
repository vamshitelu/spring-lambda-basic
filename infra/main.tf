terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.8.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
  }
}
provider "aws" {
  region = var.aws_region
}

#--------------------------------
# IAM Role for Lambda
#--------------------------------
resource "aws_iam_role" "lambda_exec" {
  name = "springboot-lambda_basic_exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#--------------------------------------
# Lambda Function
#----------------------------------------
resource "aws_lambda_function" "springboot_lambda_basic" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "com.vsoft.StreamLambdaHandler::handleRequest"
  runtime       = "java21"

  memory_size = 1024
  timeout     = 30
  filename    = "${path.module}/../target/spring-lambda.jar"
  source_code_hash = filebase64sha256("${path.module}/../target/spring-lambda.jar")
}

#----------------------------------------
# Lambda Permission (Optional: API Gateway trigger)
#----------------------------------------
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.springboot_lambda_basic.function_name
  principal    = "apigateway.amazonaws.com"
    source_arn   = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}

#----------------------------------------
# API Gateway (Optional - to expose REST endpoint)
#----------------------------------------
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "springboot-rest-api"
  description = "API Gateway for Spring Boot Lambda Function"
}

#----------------------------------------
# Root Resource
#----------------------------------------
data "aws_api_gateway_resource" "root" {
  path        = "/"
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
}

#----------------------------------------
#Resource proxy
#----------------------------------------
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = data.aws_api_gateway_resource.root.id
  path_part   = "{proxy+}"
}
#----------------------------------------
# Method for Proxy Resource
#----------------------------------------
resource "aws_api_gateway_method" "proxy_method" {
  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.proxy.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
}

#----------------------------------------
#Lambda Integration
#----------------------------------------
resource "aws_api_gateway_integration" "lambda_integration" {
  http_method = aws_api_gateway_method.proxy_method.http_method
  resource_id = aws_api_gateway_resource.proxy.id
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri         = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.springboot_lambda_basic.arn}/invocations"
}

#----------------------------------------
# Deployment
#----------------------------------------
resource "aws_api_gateway_deployment" "rest_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
}
#----------------------------------------
# Stage
#----------------------------------------
resource "aws_api_gateway_stage" "rest_api_stage" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.rest_api_deployment.id
  stage_name    = "dev"
}
output "lambda_function_name" {
  value = aws_lambda_function.springboot_lambda_basic.function_name
}

output "api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.rest_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.rest_api_stage.stage_name}"
}
