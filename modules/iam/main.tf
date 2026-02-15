# IAM Role and Instance Profile for EC2 S3 access

resource "aws_iam_role" "ec2_s3" {
  name = "${var.prefix}-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.prefix}-ec2-s3-role"
    Environment = var.environment
  }
}

resource "aws_iam_instance_profile" "ec2_s3" {
  name = "${var.prefix}-ec2-s3-profile"
  role = aws_iam_role.ec2_s3.name
}

resource "aws_iam_role_policy" "ec2_s3" {
  name = "${var.prefix}-ec2-s3-policy"
  role = aws_iam_role.ec2_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [for arn in var.s3_bucket_arns : "${arn}/*"]
      }
    ]
  })
}
