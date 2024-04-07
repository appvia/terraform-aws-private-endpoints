
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
