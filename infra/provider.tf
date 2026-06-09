provider "aws" {
  region = var.aws_region
}

data "aws_iam_role" "labrole" {
  name = "LabRole"
}