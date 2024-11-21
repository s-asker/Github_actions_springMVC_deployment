resource "aws_iam_user" "ecrecs" {
  name = "ecr-ecs"
  path = "/system/"

  tags = {
    name = "ecrUser"
  }
}

resource "aws_iam_access_key" "ecrecs" {
  user = aws_iam_user.ecrecs.name
}


resource "aws_iam_user_policy_attachment" "ecr_full_access" {
  user       = aws_iam_user.ecrecs.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_user_policy_attachment" "ecs_full_access" {
  user       = aws_iam_user.ecrecs.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}


output "aws_access_key_id" {
  value = aws_iam_access_key.ecrecs.id
}

output "aws_secret_access_key" {
  value     = aws_iam_access_key.ecrecs.secret
  sensitive = true

}