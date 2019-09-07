provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "state-dump"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "state-dump-locks"
    encrypt = true
  }
}

resource "aws_db_instance" "db_example" {
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "db_example"
  username = "admin"

  #ovo je problem
  #password = sata.aws_secretsmanager_secret_version.db_password.secret_string
  #ovo je resenje
  #Handling Key-Value Secret Strings in JSON      <- koje sam i kreirao u AWS Secrets Manager-u
  #Reading key-value pairs from JSON back into a native Terraform map can be accomplished in Terraform 0.12 and later with the jsondecode() function:
  #imam key:pair value - admin:7MasterBlaster7
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["admin"]
}

#ovo funkcionise normalno
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "pass"
}

#za produkciju mogu da kreiram novu bazu i novi secret

