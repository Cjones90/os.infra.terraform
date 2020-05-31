resource "aws_security_group" "db_ports" {
    name = "${local.vpc_name}_db_sg"
    vpc_id = aws_vpc.terraform_vpc.id
    tags = {
        Name = "${local.vpc_name}_db_sg"
    }

    ingress {
        description = "postgresql"
        from_port   = 5432
        to_port     = 5432
        cidr_blocks = [var.cidr_block]
        protocol    = "tcp"
    }
    ingress {
        description = "redis"
        from_port   = 6379
        to_port     = 6379
        cidr_blocks = [var.cidr_block]
        protocol    = "tcp"
    }
    ingress {
        description = "mongo"
        from_port   = 27017
        to_port     = 27017
        cidr_blocks = [var.cidr_block]
        protocol    = "tcp"
    }

}

resource "aws_security_group" "app_ports" {
    name = "${local.vpc_name}_app_sg"
    vpc_id = aws_vpc.terraform_vpc.id
    tags = {
        Name = "${local.vpc_name}_app_sg"
    }

    # If we ever seperate 80/443 to external load balancers we can move to diff group
    ingress {
        description = "http"
        from_port   = 80
        to_port     = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }
    ingress {
        description = "https"
        from_port   = 443
        to_port     = 443
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }

    # App/Api
    ingress {
        description = "Docker Swarm TCP2"
        from_port   = 2377
        to_port     = 2377
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }
    ingress {
        description = "Docker Swarm TCP1"
        from_port   = 7946
        to_port     = 7946
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }
    ingress {
        description = "Docker Swarm UDP2"
        from_port   = 4789
        to_port     = 4789
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "udp"
    }
    ingress {
        description = "Docker Swarm UDP1"
        from_port   = 7946
        to_port     = 7946
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "udp"
    }
    ingress {
        description = "Docker Bridge"
        from_port   = 0
        to_port     = 65535
        cidr_blocks = ["172.16.0.0/12"]
        protocol    = "tcp"
    }
    # We allow all ports by default for user, but this will ensure we can at least
    #  make a docker-machine connection even if that rule is deleted
    ingress {
        description = "Docker Machine (user)"
        from_port   = 2376
        to_port     = 2376
        cidr_blocks = ["${var.docker_machine_ip}/32"]
        protocol    = "tcp"
    }
}


resource "aws_security_group" "admin_ports" {
    name = "${local.vpc_name}_admin_sg"
    vpc_id = aws_vpc.terraform_vpc.id
    tags = {
        Name = "${local.vpc_name}_admin_sg"
    }

    ingress {
        description = "http"
        from_port   = 80
        to_port     = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }
    ingress {
        description = "https"
        from_port   = 443
        to_port     = 443
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }

    ingress {
        description = "LetsEncrypt"
        from_port   = 7080
        to_port     = 7080
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }
    # Soon to deprecate chef
    ingress {
        description = "Chef_Http"
        from_port   = 8888
        to_port     = 8888
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }
    ingress {
        description = "Chef_Https"
        from_port   = 4433
        to_port     = 4433
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }
    ingress {
        description = "Chef oc_bifrost"
        from_port   = 9683
        to_port     = 9683
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }
}


resource "aws_security_group" "default_ports" {
    name = "${local.vpc_name}_default_sg"
    vpc_id = aws_vpc.terraform_vpc.id
    tags = {
        Name = "${local.vpc_name}_default_sg"
    }

    ingress {
        description = "ssh"
        from_port   = 22
        to_port     = 22
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "tcp"
    }
    ingress {
        description = "localhost1"
        from_port   = 0
        to_port     = 65535
        cidr_blocks = ["127.0.0.0/20"]
        protocol    = "tcp"
    }
    ingress {
        description = "localhost2"
        from_port   = 0
        to_port     = 65535
        cidr_blocks = ["192.168.0.0/20"]
        protocol    = "tcp"
    }

    # Default allow terraform user to every port
    ingress {
        description = "All User"
        from_port   = 0
        to_port     = 65535
        cidr_blocks = ["${var.docker_machine_ip}/32"]
        protocol    = "tcp"
    }

    # Consul communication between vpc
    ingress {
        description = "consul1"
        from_port   = 8300
        to_port     = 8302
        cidr_blocks = [var.cidr_block]
        protocol    = "tcp"
    }
    ingress {
        description = "consul2"
        from_port   = 8400
        to_port     = 8400
        cidr_blocks = [var.cidr_block]
        protocol    = "tcp"
    }
    ingress {
        description = "consul3"
        from_port   = 8500
        to_port     = 8500
        cidr_blocks = [var.cidr_block]
        protocol    = "tcp"
    }
    ingress {
        description = "consul4"
        from_port   = 8600
        to_port     = 8600
        cidr_blocks = [var.cidr_block]
        protocol    = "tcp"
    }

    egress {
        description = "All traffic"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "-1"
    }
}

resource "aws_security_group" "ext_db" {
    name = "${local.vpc_name}_ext_db_sg"
    vpc_id = aws_vpc.terraform_vpc.id
    tags = {
        Name = "${local.vpc_name}_ext_db_sg"
    }

    ingress {
        description = "postgresql"
        from_port   = 5432
        to_port     = 5432
        cidr_blocks = [
            for OBJ in var.app_ips:
            "${OBJ.ip}/32"
        ]
        protocol    = "tcp"
    }
    ingress {
        description = "redis"
        from_port   = 6379
        to_port     = 6379
        cidr_blocks = [
            for OBJ in var.app_ips:
            "${OBJ.ip}/32"
        ]
        protocol    = "tcp"
    }
    ingress {
        description = "mongo"
        from_port   = 27017
        to_port     = 27017
        cidr_blocks = [
            for OBJ in var.app_ips:
            "${OBJ.ip}/32"
        ]
        protocol    = "tcp"
    }
}

resource "aws_security_group" "ext_remote" {
    name = "${local.vpc_name}_ext_remote_sg"
    vpc_id = aws_vpc.terraform_vpc.id
    tags = {
        Name = "${local.vpc_name}_ext_remote_sg"
    }

    ingress {
        description = "All Ports"
        from_port   = 0
        to_port     = 65535
        cidr_blocks = [
            for OBJ in var.station_ips:
            "${OBJ.ip}/32"
        ]
        protocol    = "tcp"
    }
}
