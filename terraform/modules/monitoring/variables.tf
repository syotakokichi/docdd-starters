variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_group_names" {
  type    = list(string)
  default = ["backend", "frontend"]
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "alarm_actions" {
  type    = list(string)
  default = []
}
