module "kafka_acl" {
  source      = "./modules/kafka_acl"
  policy_name = "KafkaAccessPolicy"
  topic_arn   = "arn:aws:kafka:us-west-2:123456789012:topic/kafka/very-important"
  users       = ["alice", "bob", "charlie"]
}
