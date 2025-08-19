variable  "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"
}
variable "lambda_function_name" {
    description = "The name of the Lambda function"
    type        = string
    default     = "springboot-lambda-basic"
}