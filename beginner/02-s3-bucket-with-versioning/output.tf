output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.project_bucket.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.project_bucket.arn
}

output "website_url" {
  description = "Static website URL"
  value       = aws_s3_bucket_website_configuration.project_bucket_website.website_endpoint
}

output "website_domain" {
  description = "Website domain"
  value       = aws_s3_bucket_website_configuration.project_bucket_website.website_domain
}