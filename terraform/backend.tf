terraform {
  backend "s3" {
    bucket         = "devops-exam-terraform-state-snguyen"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-snguyen"
  }
} 