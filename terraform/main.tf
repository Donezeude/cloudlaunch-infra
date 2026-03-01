provider "aws" {
    region = "us-east-1"
}




data "http" "my_ip" {
    url = "https://api.ipify.org"
}

resource "aws_security_group" "allow_all_my_ip" {
    name = "allow_all_my_ip"

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    }

    tags = {
        Name = "allow-all-my-ip"
    }
}




resource "aws_instance" "debian_instance" {
    ami             = "ami-0f9c27b471bdcd702" # Debian 13 // user: admin
    instance_type   = "t3.micro"
    key_name        = "my-key-pair"

    tags = {
        Name        = "1stEC2Instance"
    }
}