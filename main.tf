terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}
variable "github_token" {
  description = "yout github token"
}
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  #profile = Nalla-user
}

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
}


resource "github_repository" "myrepo" {
    name = "dockerization-webapi"
    visibility = "public"
    auto_init = true
}

resource "github_branch" "main" {
    branch = "main"
    repository = github_repository.myrepo.name
}

variable "files" {
    default = ["bookstore-api.py", "docker-compose.yml", "requirements.txt", "Dockerfile","main.tf", "README.md"]
}

resource "github_repository_file" "app-files" {
    for_each = toset(var.files)
    content  = file(each.value) 
    file = each.value
    repository = github_repository.myrepo.name
    branch = "main"
    commit_message = "committed by Terraform"
    overwrite_on_create = true
}

resource "aws_security_group" "tf-docker-sec-gr" {
    name = "docker-sec-gr-203"
    tags = {
      Name = "dokcer-sec-group-203"
    }

    ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "tf-docker-ec2" {
    ami = "ami-04cb4ca688797756f"
    instance_type = "t2.micro"
    key_name = "xxxxxx"
    vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
    tags = {
        Name = "Web Server of Bookstore"
    }

    user_data = <<-EOF
          #!/bin/bash
          dnf update -y
          dnf install -y docker
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          newgrp docker
          curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose
          mkdir -p /home/ec2-user/dockerization-webapi
          TOKEN="$github_token"
          FOLDER="https://$TOKEN@raw.githubusercontent.com/Nalla06/dockerization-webapi/main/"
          curl -s --create-dirs -o "/home/ec2-user/dockerization-webapi/app.py" -L "$FOLDER"bookstore-api.py
          curl -s --create-dirs -o "/home/ec2-user/dockerization-webapi/requirements.txt" -L "$FOLDER"requirements.txt
          curl -s --create-dirs -o "/home/ec2-user/dockerization-webapi/Dockerfile" -L "$FOLDER"Dockerfile
          curl -s --create-dirs -o "/home/ec2-user/dockerization-webapi/docker-compose.yml" -L "$FOLDER"docker-compose.yml
          cd /home/ec2-user/dockerization-webapi
          docker build -t nalladocker/dockerization-webapi:latest .
          docker-compose up -d
  EOF
  depends_on = [github_repository.myrepo, github_repository_file.app-files]

}

output "website" {
  value = "http://${aws_instance.tf-docker-ec2.public_dns}"
}

