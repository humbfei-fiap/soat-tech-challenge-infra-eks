resource "aws_vpc" "soat_tech_challenge_vpc" {
  cidr_block = "10.0.0.0/16" # This is the CIDR block for the VPC.
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "soat-tech-challenge-vpc"
  }
}

resource "aws_subnet" "soat_tech_challenge_public_subnet_1" {
  vpc_id = aws_vpc.soat_tech_challenge_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "soat-tech-challenge-public-subnet-1"
  }
}

resource "aws_subnet" "soat_tech_challenge_public_subnet_2" {
  vpc_id = aws_vpc.soat_tech_challenge_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "soat-tech-challenge-public-subnet-2"
  }
}

resource "aws_subnet" "soat_tech_challenge_private_subnet_1" {
  vpc_id = aws_vpc.soat_tech_challenge_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "soat-tech-challenge-private-subnet-1"
  }
}

resource "aws_subnet" "soat_tech_challenge_private_subnet_2" {
  vpc_id = aws_vpc.soat_tech_challenge_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "soat-tech-challenge-private-subnet