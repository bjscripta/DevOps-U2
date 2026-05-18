provider "aws" {
  region = var.aws_region
}

data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

data "aws_iam_role" "lab" {
  name = "LabRole"
}