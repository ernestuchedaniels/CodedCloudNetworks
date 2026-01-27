output "peering_attachments" {
  description = "Peering attachment IDs (one per region pair, shared by PE and NPE)"
  value = {
    "us-east-1_to_us-west-2"      = aws_ec2_transit_gateway_peering_attachment.use1_to_usw2.id
    "us-east-1_to_eu-west-1"      = aws_ec2_transit_gateway_peering_attachment.use1_to_euw1.id
    "us-east-1_to_ap-southeast-1" = aws_ec2_transit_gateway_peering_attachment.use1_to_apse1.id
    "us-west-2_to_eu-west-1"      = aws_ec2_transit_gateway_peering_attachment.usw2_to_euw1.id
    "us-west-2_to_ap-southeast-1" = aws_ec2_transit_gateway_peering_attachment.usw2_to_apse1.id
    "eu-west-1_to_ap-southeast-1" = aws_ec2_transit_gateway_peering_attachment.euw1_to_apse1.id
  }
}
