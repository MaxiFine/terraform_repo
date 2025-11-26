resource "aws_iam_role" "ssm_role" {
    name = "MX-SSM-Demo-Role"
    assume_role_policy = jsonencode ({
        Version = "2012-10-17", 
        Statement = [
            {
                Effect = "Allow", 
                Principal = {
                    Service = "ec2.amazonaws.com"
                }, 
                Action = "sts:AssumeRole"
            }
        ]
    })
}


# USING AWS Managed Policy FOR SSM
resource "aws_iam_role_policy_attachment" "ssm_role_attachment"{
    role = aws_iam_role.ssm_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent permissions for metrics and logs
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
    role       = aws_iam_role.ssm_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


resource "aws_iam_instance_profile" "ssm_instance_profile" {
    name = "MX-SSM-Demo-Instance-Profile"
    role = aws_iam_role.ssm_role.name
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type = map(string)
    default = {
        Project = "MX-SSM-Demo"
        ETA = "2024-06-01"
        Purpose = "Demo SSM Access"
        Blocker = "Maxwell Adomako"
    }
}