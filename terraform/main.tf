resource "aws_key_pair" "food" {
  key_name   = var.key_name
  public_key = file("${path.module}/keys/food-key.pub")
}

resource "aws_security_group" "food" {

  name = "foodexpress"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "food" {

  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.food.key_name
  vpc_security_group_ids = [aws_security_group.food.id]

  tags = {
    Name = "FoodExpress"
  }
}