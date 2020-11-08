resource "aws_api_gateway_rest_api" "fb_bot_api" {
  name        = "fb_bot_api"
  description = "Api to be used as webhook"
}
