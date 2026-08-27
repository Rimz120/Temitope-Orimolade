resource "aws_rds_cluster" "lab" {
  cluster_identifier     = "${var.project_name}-cluster"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "16.9"
  database_name          = var.db_name
  master_username        = var.master_username
  master_password        = var.master_password
  db_subnet_group_name   = aws_db_subnet_group.lab.name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  # This is the key setting that lets Postgres roles authenticate via
  # short lived IAM tokens instead of static passwords, which is what
  # makes the "AD group -> IAM role -> DB role" chain possible.
  iam_database_authentication_enabled = true

  serverlessv2_scaling_configuration {
    min_capacity = var.min_acu
    max_capacity = var.max_acu
  }

  skip_final_snapshot = true # lab only, never do this for real data
  apply_immediately    = true

  tags = {
    Project = var.project_name
  }
}

resource "aws_rds_cluster_instance" "lab" {
  identifier          = "${var.project_name}-instance-1"
  cluster_identifier  = aws_rds_cluster.lab.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.lab.engine
  engine_version      = aws_rds_cluster.lab.engine_version
  publicly_accessible = true

  tags = {
    Project = var.project_name
  }
}
