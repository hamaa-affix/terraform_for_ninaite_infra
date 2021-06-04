#=========================================
#ecs task execution role
#=========================================
resource "aws_iam_role" "ecs_service_role" {
  name = "${var.env}_${var.project}_ecs_task_execution_role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      },
    ]
  })
}

#=============================================
#attach task execution policy
#=============================================
resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name = "${var.env}_${var.project}_ecs_task_execution_policy"
  role = aws_iam_role.ecs_service_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "kms:Decrypt",
          "ssm:GetParameters"
        ],
        Resource = [
          aws_kms_key.application.arn,
          aws_ssm_parameter.mysql_password.arn,
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_ecs_task_execution_role_policy_to_ecs_service_role_attachment" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#=============================================
# ecs service role
#=============================================
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.env}_${var.project}_ecs_task_role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
            "ecs-tasks.amazonaws.com"
          ]
        }
      },
    ]
  })
}

#==============================================
#ecs seevice policy
#==============================================
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "${var.env}_${var.project}_ecs_service_policy"
  role = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:*"
        ],
        Resource = "*"
      },
      {
        Sid    = "SendMail"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_ecs_task_role_policy_to_ecs_service_role_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
