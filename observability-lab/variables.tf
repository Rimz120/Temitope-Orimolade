variable "aws_region" {
  description = "AWS region for the lab"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to tag/prefix resources"
  type        = string
  default     = "groupid-lab"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "labdb"
}

variable "master_username" {
  description = "Master (admin) username for the cluster"
  type        = string
  default     = "labadmin"
}

variable "master_password" {
  description = "Master password. Pass via TF_VAR_master_password env var, never commit this."
  type        = string
  sensitive   = true
}

variable "min_acu" {
  description = "Aurora Serverless v2 minimum capacity units. 0.5 is the floor and still costs money while running."
  type        = number
  default     = 0.5
}

variable "max_acu" {
  description = "Aurora Serverless v2 maximum capacity units"
  type        = number
  default     = 1.0
}

variable "my_ip_cidr" {
  description = "Your local IP in CIDR form (e.g. 1.2.3.4/32), so the security group only lets you connect"
  type        = string
}

# This simulates the AD security group from the Slack thread. In your
# corporate setup this is an actual AD GroupID synced into an IAM role
# via SAML/IdP federation. Here we just name the concept explicitly.
variable "access_group_name" {
  description = "Name of the group that maps to write access on specific tables (stand-in for the AD GroupID)"
  type        = string
  default     = "printer-admins"
}

variable "writable_tables" {
  description = "Tables the access group should get write access to"
  type        = list(string)
  default     = ["printers", "printer_assignments"]
}
