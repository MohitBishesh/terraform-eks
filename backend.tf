# Local backend by default (suitable for a solo take-home).
# For shared/EC2 usage, uncomment and configure the S3 backend below,
# then run: terraform init -migrate-state
#
# terraform {
#   backend "s3" {
#     bucket         = "YOUR_TF_STATE_BUCKET"
#     key            = "devops-take-home/eks/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "YOUR_TF_LOCK_TABLE"
#   }
# }

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
