variable "server_port" {
  description = "the port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "cluster_name" {
  description = "name used for all cluster resources"
  type = string
}

variable "db_remote_state_bucket" {
  type = "string"
  description = "remote state S3 bucket"
}

variable "db_remote_state_key" {
  type = "string"
  description = "S3 path"
}

variable "instance_type" {
  type = "string"
  description = "EC2 type"
}

variable "min_size" {
  type = number
  description = "min number of instances in the autoscaling group"
}

variable "max_size" {
  type = number
  description = "max number of instances in the autoscaling group"
}