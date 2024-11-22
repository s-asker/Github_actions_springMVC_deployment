provider "aws" {
  region = "us-east-2"
}


###################### DB AND EC2 ###########################
resource "aws_db_instance" "db" {
  allocated_storage      = 10
  db_name                = "accounts"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  identifier             = "db-instance"
  password               = random_password.rds_password.result
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.dbsg.id]
} # Default configuration, take care of your credentials

resource "aws_instance" "web" {
  ami                    = "ami-0ea3c35c5c3284d82"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2ssh.id]
  key_name               = aws_key_pair.ec2key.key_name
  tags = {
    Name = "db-client"
  }
}

######################################################

resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
} # For generating random password for the database


############### KEYPAIR ###########################
resource "aws_key_pair" "ec2key" {
  key_name   = "dbinstance"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDb9k3Id0jaSKcsZGg8EFD0j3879ur5ROlyOvKuPf0rh2UEzC6P4g5P/3jJFPu9pMAj/zMaJ9TixovNoCTat5GS5H5LaDgUSAsm7PZmuRWVN8NObdSz+bYJ1FvAQl3/ATc6Bcjt/+SLiqNyOtOyBt4vInRoCfbQDFeYaOeZfgYKePtkl8SHnd+M1IDQk5r2wbr5ty68fiWzLE1vYPfuasNGWS5WUVmhA10m77rfH5+mu57SMeW+DsXwo/NBXZnGNjBpgZn5t4/ggNCRBFwPPVF+J4RWomctqbPCN/HdKZep7lYqrpyrRvTRj6vgY+lSso3/VBugtz5inBVkMWw3AT6dwp0KVYxIZ2y4UBtpG4Yh+C0BoEPqDLsOmHLvx+VXhtMeXDLMJY/hn8tzWSW9zrxoiMVylamR2+cEtajUSKI+YGxhijd+iW2uPaBNuUzzrKdzwOHHM/Ql6hpN4u/J0K3Qy8dJnDQl3hzJ/n3s2x68G4K64aqdMjYlya543pExpHs= sheri@Asker"
} # Generated the public key using ssh-keygen

##################################################

################ SECURITY GROUPS ###########################
resource "aws_security_group" "ec2ssh" {
  name        = "ec2_ssh"
  description = "Allow ssh inbound traffic"

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_rules" {
  security_group_id = aws_security_group.ec2ssh.id
  cidr_ipv4         = "0.0.0.0/0" # It should be your ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_security_group" "dbsg" {
  name        = "dbsg"
  description = "Allow connection from ec2 instance created"

  tags = {
    Name = "dbconn"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2db_rules" {
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.dbsg.id
  from_port                    = "3306"
  referenced_security_group_id = aws_security_group.ec2ssh.id # Accept connection from ec2 instance only
  to_port                      = "3306"
}
resource "aws_vpc_security_group_ingress_rule" "ecsdb_rules" {
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.dbsg.id
  from_port                    = "3306"
  referenced_security_group_id = aws_security_group.ecs_sg.id # Accept connection from ec2 instance only
  to_port                      = "3306"
}

resource "aws_vpc_security_group_egress_rule" "egress_all_ec2" {
  security_group_id = aws_security_group.ec2ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}
resource "aws_vpc_security_group_egress_rule" "egress_all_db" {
  security_group_id = aws_security_group.dbsg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}


##################################################################


