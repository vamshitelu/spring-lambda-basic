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
}

#----------------------------------------
# API Gateway (Optional - to expose Http endpoint)
#----------------------------------------
resource "aws_apigatewayv2_api" "http_api" {
  name        = "springboot-http-api"
  description = "API Gateway for Spring Boot Lambda Function"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri = "aws_lambda_function.speingboot_lambda_basic.invoke_arn"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "default_route"{
  api_id = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.http_api.id
  name   = "$default"
  auto_deploy = true
}

output "lambda_function_name" {
  value = aws_lambda_function.speingboot_lambda_basic.function_name
}

output "api_endpoint" {
  value = aws_apigatewayv2_stage.default.invoke_url
}