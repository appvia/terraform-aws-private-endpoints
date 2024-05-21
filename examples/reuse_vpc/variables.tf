
variable "ram_principals" {
  description = "A list of the ARNs of the principals to associate with the resource"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_id" {
  description = "The ID of the transit gateway to connect the VPC to"
  type        = string
  default     = null
}

variable "ipam_pool_id" {
  description = "The ID of the IPAM pool to use for the VPC"
  type        = string
  default     = null
}

variable "region" {
  description = "The region to create the VPC in"
  type        = string
  default     = "eu-west-2"
}
