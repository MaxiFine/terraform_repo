resource "aws_secretsmanager_secret" "main" {
    name                        = "${var.name}"
    description                 = "${var.description}"
    tags                        = "${merge(var.tags,
                                            tomap({"Name" = "${var.name} Secrets Manager Secret"}))}"
}

resource "aws_secretsmanager_secret_version" "main" {
    secret_id                   = aws_secretsmanager_secret.main.id
    secret_string               = base64encode(var.secret_string)
}

