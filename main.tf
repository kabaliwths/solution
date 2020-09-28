resource "aws_cloudwatch_event_rule" "ecs_taskupdate" {
  name                = "ecs_taskupdate"
  description         = "Update ecs task"

  event_pattern = <<EOF
  {
        "source": [
            "aws.ecr"
        ],
        "detail-type": [
            "ECR Image Action"
        ],
        "detail": {
            "action-type": [
                "PUSH"
            ],
            "result": [
                "SUCCESS"
            ]
        }
   }
EOF
}



resource "aws_cloudwatch_event_target" "check_foo_every_one_minute" {
  rule      = aws_cloudwatch_event_rule.ecs_taskupdate.name
  target_id = "lambda"
  arn       = aws_lambda_function.ecs_update.arn
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${aws_lambda_function.ecs_update.function_name}"
  retention_in_days = 3
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "ecs_update" {
  filename      = "function.zip"
  function_name = "ecs_update"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "function.lambda_handler"
  source_code_hash = filebase64sha256("function.zip")

  runtime = "python3.6"
}


resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_update.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_taskupdate.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "ecs" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_ecr_repository" "hello" {
  name                 = "production/hello"

  image_scanning_configuration {
    scan_on_push = false
  }
}