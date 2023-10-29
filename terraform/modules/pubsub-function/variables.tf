variable "bucket_name" {
  type        = string
  default     = ""
  description = "The bucket to store function source code."
}

variable "source_dir" {
  type        = string
  description = "The pathname of the directory which contains the function source code."
}
variable "project_id" {
  type        = string
  description = "The project where resources will be created."
}

variable "name" {
  type        = string
  description = "The name of the cloud function."
}

variable "description" {
  type        = string
  default     = "Processes events."
  description = "The description of the cloud function."
}

variable "location" {
  type        = string
  description = "The location of the cloud function."
}

variable "runtime" {
  type        = string
  default     = "nodejs18"
  description = "The runtime in which the function will be executed."
}

variable "entry_point" {
  type        = string
  description = "The name of a method in the function source which will be invoked when the function is executed."
}

variable "pubsub_topic" {
  type        = string
  description = "The name of a Pub/Sub topic."
}

variable "service_account_email" {
  type        = string
  description = "The existing service account to run cloud function."
  default     = ""
}

variable "timeout" {
  type        = number
  default     = 540
  description = "The function execution timeout."
}

variable "available_memory" {
  type        = string
  default     = "256M"
  description = "The amount of memory allotted for the function to use."
}

variable "min_instance_count" {
  type        = number
  default     = null
  description = "The limit on the minimum number of function instances that may coexist at a given time."
}

variable "max_instance_count" {
  type        = number
  default     = 1
  description = "The limit on the maximum number of function instances that may coexist at a given time."
}

variable "ingress_settings" {
  type        = string
  default     = "ALLOW_INTERNAL_ONLY"
  description = "The ingress settings for the function."
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "A set of key/value environment variable pairs to assign to the function."
}