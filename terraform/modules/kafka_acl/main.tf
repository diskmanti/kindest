variable "policy_name" {
  description = "Name of the IAM policy to create"
  type        = string
}

variable "topic_arn" {
  description = "ARN of the Kafka topic"
  type        = string
}

variable "actions" {
  description = "List of Kafka actions allowed"
  type        = list(string)
  default     = [
    "kafka-cluster:Connect",
    "kafka-cluster:DescribeTopic",
    "kafka-cluster:ReadData"
  ]
}

variable "users" {
  description = "List of IAM user names to attach the policy to"
  type        = list(string)
}

resource "aws_iam_policy" "kafka_policy" {
  name        = var.policy_name
  description = "Kafka access policy"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = var.actions,
        Resource = var.topic_arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "kafka_policy_attachments" {
  for_each   = toset(var.users)
  user       = each.key
  policy_arn = aws_iam_policy.kafka_policy.arn
}
