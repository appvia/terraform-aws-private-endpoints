
## Provision the association between a principal and a resource share
resource "aws_ram_principal_association" "association" {
  for_each = toset(var.ram_principals)

  principal          = each.value
  resource_share_arn = var.ram_resource_share_arn
}
