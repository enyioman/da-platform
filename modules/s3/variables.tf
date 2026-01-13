variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "dals-language"
}

variable "enable_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Enable lifecycle policies for S3 bucket"
  type        = bool
  default     = true
}

variable "enable_cors" {
  description = "Enable CORS configuration for S3 bucket"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
