# For a personal lab, reuse the account's default VPC instead of building
# a whole new one. Your real team infra almost certainly uses a purpose
# built VPC with private subnets for the DB tier; this is intentionally
# simplified so the AD Group -> IAM -> Postgres pattern is the focus.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "lab" {
  name       = "${var.project_name}-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Project = var.project_name
  }
}

resource "aws_security_group" "aurora" {
  name        = "${var.project_name}-aurora-sg"
  description = "Allows Postgres access from your IP only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Postgres from my IP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
  }
}
