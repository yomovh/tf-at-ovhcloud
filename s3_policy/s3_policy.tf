########################################################################################
# This script creates an S3 bucket along with 3 S3 users and gives differents policies to the different users
#
# It requires the following variables to be defined for the OVH provider :
# OVH_ENDPOINT
# OVH_APPLICATION_KEY
# OVH_APPLICATION_SECRET
# OVH_CONSUMER_KEY
# The following is required specifically for this script:
# TF_VAR_OVH_PUBLIC_CLOUD_PROJECT_ID that shall be filled with your public cloud project id or it will be requested on script startup
########################################################################################


########################################################################################
#     Variables
########################################################################################
variable ovh_public_cloud_project_id{
  type = string
}

variable region {
  type        = string
  default     = "gra"
}

variable s3_endpoint {
  type        = string
  default     = "https://s3.gra.io.cloud.ovh.net"
}

variable user_desc_prefix {
  type        = string
  default     = "[TF] User created by s3 terraform script"
}

variable bucket_name {
   type       = string
   default    ="tf-s3-bucket-policy"
}
variable object_name {
  type = string
  default = "test_file.txt"
}


#######################################################################################
#     Providers
########################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    ovh = {
      source  = "ovh/ovh"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
    region      = var.region
    access_key  = ovh_cloud_project_user_s3_credential.s3_admin_cred.access_key_id
    secret_key  = ovh_cloud_project_user_s3_credential.s3_admin_cred.secret_access_key

    #OVH implementation has no STS service
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    # the gra region is unknown to AWS hence skipping is needed.
    skip_region_validation = true
    endpoints {
        s3 = var.s3_endpoint
    }
}


########################################################################################
#     User / Credential
########################################################################################
resource "ovh_cloud_project_user" "s3_admin_user" {
  service_name = var.ovh_public_cloud_project_id
  description = "${var.user_desc_prefix} that is used to create S3 bucket"
  role_name = "objectstore_operator"
} 
resource "ovh_cloud_project_user_s3_credential" "s3_admin_cred"{
  service_name = var.ovh_public_cloud_project_id
  user_id = ovh_cloud_project_user.s3_admin_user.id
}
resource "ovh_cloud_project_user" "write_user" {
  service_name = var.ovh_public_cloud_project_id
  description = "${var.user_desc_prefix} that will have write access to the bucket"
  role_name = "objectstore_operator"
}

resource "ovh_cloud_project_user_s3_credential" "write_cred"{
  service_name = var.ovh_public_cloud_project_id
  user_id = ovh_cloud_project_user.write_user.id
}

resource "ovh_cloud_project_user" "read_user" {
  service_name = var.ovh_public_cloud_project_id
  description = "${var.user_desc_prefix} that will have read access to the bucket"
  role_name = "objectstore_operator"
}
resource "ovh_cloud_project_user_s3_credential" "read_cred"{
  service_name = var.ovh_public_cloud_project_id
  user_id = ovh_cloud_project_user.read_user.id
}


########################################################################################
#     Bucket
########################################################################################
resource "aws_s3_bucket" "b"{
  bucket = "${var.ovh_public_cloud_project_id}-${var.bucket_name}"
}

resource "aws_s3_object" "object"{
  bucket = aws_s3_bucket.b.bucket
  key = var.object_name
  content = "This is a small text, used to test the object from terraform"
}
########################################################################################
#     Policy
########################################################################################

resource "ovh_cloud_project_user_s3_policy" "write_policy" {
  service_name = var.ovh_public_cloud_project_id
  user_id      = ovh_cloud_project_user.write_user.id
  policy       = jsonencode({
    "Statement":[{
      "Sid": "RWContainer",
      "Effect": "Allow",
      "Action":["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:ListMultipartUploadParts", "s3:ListBucketMultipartUploads", "s3:AbortMultipartUpload", "s3:GetBucketLocation"],
      "Resource":["arn:aws:s3:::${aws_s3_bucket.b.bucket}", "arn:aws:s3:::${aws_s3_bucket.b.bucket}/*"]
    }]
  })
}

resource "ovh_cloud_project_user_s3_policy" "read_policy" {
  service_name = var.ovh_public_cloud_project_id
  user_id      = ovh_cloud_project_user.read_user.id
  policy       = jsonencode({
    "Statement":[{
      "Sid": "ROContainer",
      "Effect": "Allow",
      "Action":["s3:GetObject", "s3:ListBucket", "s3:ListMultipartUploadParts", "s3:ListBucketMultipartUploads"],
      "Resource":["arn:aws:s3:::${aws_s3_bucket.b.bucket}", "arn:aws:s3:::${aws_s3_bucket.b.bucket}/*"]
    }]
  })
}

########################################################################################
#     Output
########################################################################################
output "admin_access_key" {
  description = "the access key that have been used to create the bucket"
  value = ovh_cloud_project_user_s3_credential.s3_admin_cred.access_key_id
}
 
output "admin_secret_key" {
  description = "the secret key that have been used to create the bucket"
  value = ovh_cloud_project_user_s3_credential.s3_admin_cred.secret_access_key
  sensitive = true
}

output "read_user_access_key" {
  description = "the access key for the user that have been provided read access to the bucket"
  value = ovh_cloud_project_user_s3_credential.read_cred.access_key_id
}
 
output "read_user_secret_key" {
  description = "the secret key for the user that have been provided read access to the bucket"
  value = ovh_cloud_project_user_s3_credential.read_cred.secret_access_key
  sensitive = true
}

output "write_user_access_key" {
  description = "the access key for the user that have been provided write access to the bucket"
  value = ovh_cloud_project_user_s3_credential.write_cred.access_key_id
}
 
output "write_user_secret_key" {
  description = "the secret key for the user that have been provided write access to the bucket"
  value = ovh_cloud_project_user_s3_credential.write_cred.secret_access_key
  sensitive = true
}

