provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "state-dump"

  #prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  #enable versioning
  versioning {
    enabled = true
  }

  #enable server-side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terrafrom_locks" {
  name         = "state-dump-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

#remote backend
terraform {
  backend "s3" {
    bucket = "state-dump"
    key = "global/s3/terraform.tf_state"
    region = "eu-central-1"

    dynamodb_table = "state-dump-locks"
    encrypt = true
  }
}

# This will NOT work. Variables aren't allowed in a backend configuration.
/*terraform {
  backend "s3" {
    bucket         = "${var.bucket}"
    region         = "${var.region}"
    dynamodb_table = "${var.dynamodb_table}"
    key            = "example/terraform.tfstate"
    encrypt        = true
  }
}
*/


output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "Backend S3 bucket ARN"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terrafrom_locks.name
  description = "DynamoDB name"
}





























