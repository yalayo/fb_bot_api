# Rest api
resource "aws_api_gateway_rest_api" "fb_bot_api" {
  name        = "fb_bot_api"
  description = "Api to be used as webhook"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Only resource
resource "aws_api_gateway_resource" "message" {
  rest_api_id = aws_api_gateway_rest_api.fb_bot_api.id
  parent_id   = aws_api_gateway_rest_api.fb_bot_api.root_resource_id
  path_part   = "message"
}

# GET Method
resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.fb_bot_api.id
  resource_id   = aws_api_gateway_resource.message.id
  http_method   = "GET"
  authorization = "NONE"
}

# Method response 200
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.fb_bot_api.id
  resource_id = aws_api_gateway_resource.message.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_settings" "s" {
  rest_api_id = aws_api_gateway_rest_api.fb_bot_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "${aws_api_gateway_resource.message.path_part}/${aws_api_gateway_method.get.http_method}"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

# Deployment for stage dev
resource "aws_api_gateway_deployment" "dev" {
  depends_on  = [aws_api_gateway_integration.mock]
  rest_api_id = aws_api_gateway_rest_api.fb_bot_api.id
  stage_name  = "dev"
}

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.fb_bot_api.id
  deployment_id = aws_api_gateway_deployment.dev.id
}

# Mock integration
resource "aws_api_gateway_integration" "mock" {
  rest_api_id = aws_api_gateway_rest_api.fb_bot_api.id
  resource_id = aws_api_gateway_resource.message.id
  http_method = aws_api_gateway_method.get.http_method
  type        = "MOCK"
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<EOF
      {
        #if($input.params('hub.mode') == "subscribe" && $input.params('hub.verify_token') == "verify_token")
          "statusCode": 200
        #else
          "statusCode": 500
        #end
      }
     EOF
  }
}

# Integration response
resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.fb_bot_api.id
  resource_id = aws_api_gateway_resource.message.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_templates = {
    "application/json" = <<EOF
       $input.params('hub.challenge')
    EOF
  }
}
