module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name = var.name

  vpc_id          = aws_vpc.main.id
  subnets         = [aws_subnet.public[0].id, aws_subnet.public[1].id]
#   security_groups = [module.alb_http_sg.security_group_id]
  security_group_rules = {
    ingress_all_http = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name             = var.name
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    },
  ]

  tags = local.tags
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.10.0"

  # Autoscaling group
  name = var.name

  min_size                  = 2
  max_size                  = 2
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  vpc_zone_identifier       = [aws_subnet.public[0].id, aws_subnet.public[1].id]

  target_group_arns = module.alb.target_group_arns

  # Launch template
  launch_template_name        = var.name
  launch_template_description = "Launch template example"
  update_default_version      = true

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.nano"

  create_iam_instance_profile = true
  iam_role_name               = "ssm-managed-instance-core-${var.name}"
  iam_role_path               = "/ec2/"
  iam_role_description        = "SSM role for ${var.name}"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = "dev"
    Project     = var.name
  }
}

# resource "aws_db_instance" "this" {
#   db_subnet_group_name = aws_db_subnet_group.this.name
#   allocated_storage    = 10
#   db_name              = "mydb"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t3.micro"
#   username             = "foo"
#   password             = "foobarbaz"
#   parameter_group_name = "default.mysql5.7"
#   skip_final_snapshot  = true
#   vpc_security_group_ids = [module.db_sg.security_group_id]

# #   depends_on = [aws_db_subnet_group.this]
# }

# resource "aws_db_subnet_group" "this" {
#   name       = "main"
#   subnet_ids = [aws_subnet.public[0].id, aws_subnet.public[1].id]

#   tags = local.tags
# }

module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "~> 5.0"

  name        = "${var.name}-ec2"
  vpc_id      = aws_vpc.main.id
  description = "Security group for ${var.name} ec2 instances"

  ingress_cidr_blocks = ["0.0.0.0/0"]

    computed_egress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.db_sg.security_group_id
    },
  ]

  number_of_computed_egress_with_source_security_group_id = 1

  tags = local.tags
}

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.name}-db"
  description = "Security group for ${var.name} db instance"
  vpc_id      = aws_vpc.main.id

  # ingress
  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.ec2_sg.security_group_id
    },
  ]

  number_of_computed_ingress_with_source_security_group_id = 1

  tags = local.tags
}