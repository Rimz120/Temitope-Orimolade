# --- This is the piece that plays the role of your corporate AD Group ---
#
# In your work environment, the AD security group (GroupID) is federated
# through your IdP (e.g. ADFS/Entra ID via SAML) into an IAM role. Anyone
# in that AD group can assume this role, and the role only grants
# rds-db:connect for one specific database user. Postgres then maps that
# database user to a role that has table level GRANTs. That's the whole
# chain from your Slack thread, reproduced here without an IdP:
#
#   AD Group (GroupID) --SAML federation--> IAM Role --rds-db:connect-->
#   Postgres DB user "printer_admins_iam" --GRANT-->  printers, printer_assignments
#
# Since you don't have a corporate IdP here, this role is assumable
# directly by your own AWS account's root/admin principal, just so you
# can test the rds-db:connect + Postgres GRANT chain end to end.

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "access_group" {
  name = "${var.project_name}-${var.access_group_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    RepresentsGroup = var.access_group_name
  }
}

resource "aws_iam_role_policy" "db_connect" {
  name = "${var.project_name}-rds-connect"
  role = aws_iam_role.access_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["rds-db:connect"]
        # Scoped to one specific Postgres user, so this role can only
        # ever authenticate as that narrow, table-restricted user.
        Resource = "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_rds_cluster.lab.cluster_resource_id}/printer_admins_iam"
      }
    ]
  })
}
