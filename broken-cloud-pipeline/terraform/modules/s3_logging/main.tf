resource "aws_s3_bucket" "this" {
  bucket_prefix = "${var.name}-logs-"
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred" 
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket     = aws_s3_bucket.this.id
  acl        = "log-delivery-write" # Allows ELB to write logs, it is there is aws docs
  depends_on = [aws_s3_bucket_ownership_controls.this]
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {
      prefix = "" # Applies to all objects
    }
    expiration {
      days = 90 # Logs expire after 90 days
    }
  }
}
resource "aws_s3_bucket_policy" "this" {
  bucket     = aws_s3_bucket.this.id
  policy     = <<EOF
{
  "Version": "2012-10-17",
  "Id": "MultiLogPolicy",
  "Statement": [
    {
      "Sid": "AllowELBLogging",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::054676820928:root"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.this.arn}/alb/*"
    },
    {
      "Sid": "AllowECSContainerLogs",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.this.arn}/ecs/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
EOF
  depends_on = [aws_s3_bucket.this, aws_s3_bucket_acl.this]
}
