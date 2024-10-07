output "arn" {
  description = "SSL certificate."
  value       = module.acm.acm_certificate_arn
}
