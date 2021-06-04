variable "region" {
  default = "ap-northeast-1"
}

variable "project" {
  default = "ninaite"
}

variable "env" {
  default = "dev"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "domain" {
  default = "ninaite.work"
}

variable "sub_domain" {
  default = "dev"
}

variable "rds_password" {
  type = string
}
