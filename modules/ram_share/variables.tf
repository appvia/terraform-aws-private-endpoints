
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "ram_resource_share_arn" {
  description = "The ARN of the RAM share to associate with the resource"
  type        = string
}

variable "ram_principals" {
  description = "A list of the ARNs of the principals to associate with the resource"
  type        = list(string)
  default     = []
}
