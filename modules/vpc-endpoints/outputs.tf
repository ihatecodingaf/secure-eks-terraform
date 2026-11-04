output "s3_endpoint_id" {
  description = "ID of the S3 gateway endpoint."
  value       = aws_vpc_endpoint.s3.id
}

output "interface_endpoint_ids" {
  description = "Map of service name to interface endpoint ID."
  value       = { for svc, ep in aws_vpc_endpoint.interface : svc => ep.id }
}

output "security_group_id" {
  description = "Security group attached to the interface endpoints."
  value       = try(aws_security_group.endpoints[0].id, null)
}
