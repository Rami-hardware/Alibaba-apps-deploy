resource "random_id" "bucket_suffix" {
  byte_length = 6
}

resource "alicloud_oss_bucket" "nextcloud" {
  
  bucket = "nextcloud-production-${random_id.bucket_suffix.hex}"
  acl    = "private"
}