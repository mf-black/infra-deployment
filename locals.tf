locals {
  account_id = data.aws_caller_identity.current.account_id
  tags = {
    project = var.name
  }
}