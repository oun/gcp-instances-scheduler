variable "project_id" {
  type        = string
  description = "The project where resources will be created."
}

variable "scheduled_project_id" {
  type        = string
  description = "The project where resources will be scheduled start and stop."
}

variable "region" {
  type        = string
  description = "The region in which resources will be applied."
}