variable "db_password" {
  description = "Nextcloud DB password"
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  type = string
}