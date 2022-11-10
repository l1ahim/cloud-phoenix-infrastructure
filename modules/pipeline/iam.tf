/*
    DATA SOURCES
*/

data "aws_iam_policy_document" "codebuild_role" {
  statement {
    sid = "CodeBuildAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "codepipeline_role" {
  statement {
    sid = "CodePipelineAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    sid = "PermissionsCodeBuild"

    actions = [
      "codecommit:GitPull",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "codestar-connections:UseConnection",
      "codestar-connections:FullRepositoryId",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecs:RunTask",
      "iam:PassRole",
      "iam:DeletePolicyVersion",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ecr:*",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetBucketAcl",
      "codebuild:BatchPutTestCases",
      "s3:GetBucketLocation",
      "s3:GetObjectVersion"
    ]

    effect = "Allow"

    resources = [
      "*",
    ]
  }

  statement {
    sid = "PermissionsCodeBuildSubnet"

    actions = [
      "ec2:CreateNetworkInterfacePermission"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"
      values = formatlist(
        "arn:aws:ec2:${data.aws_region.default.name}:${data.aws_caller_identity.default.account_id}:subnet/%s",
        var.private_subnets
      )
    }

    resources = [
      "arn:aws:ec2:${data.aws_region.default.name}:${data.aws_caller_identity.default.account_id}:network-interface/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values = [
        "codebuild.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    sid = "PermissionsCodePipeline"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
      "cloudwatch:*",
      "s3:*",
      "ecs:*",
      "ecr:DescribeImages",
      "codestar-connections:UseConnection",
      "codestar-connections:FullRepositoryId"
    ]

    effect = "Allow"

    resources = [
      "*",
    ]
  }
}

/*
    RESOURCES
*/

resource "aws_iam_policy" "codebuild" {
  name   = "policy-codebuild-role"
  path   = var.iam_policy_path
  policy = data.aws_iam_policy_document.codebuild_policy.json
  tags   = var.tags
}

resource "aws_iam_policy" "codepipeline" {
  name   = "policy-codepipeline-role"
  path   = var.iam_policy_path
  policy = data.aws_iam_policy_document.codepipeline_policy.json
  tags   = var.tags
}

resource "aws_iam_role" "codebuild_role" {
  name                  = "${var.app_name}_codebuild_role"
  assume_role_policy    = data.aws_iam_policy_document.codebuild_role.json
  force_detach_policies = true

  tags                  = var.tags #might be fixed to indicate the role and not policy
}

resource "aws_iam_role" "codepipeline_role" {
  name                  = "${var.app_name}_codepipeline_role"
  assume_role_policy    = data.aws_iam_policy_document.codepipeline_role.json
  force_detach_policies = true

  tags                  = var.tags
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  policy_arn = join("", aws_iam_policy.codebuild.*.arn)
  role       = join("", aws_iam_role.codebuild_role.*.id)
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  policy_arn = join("", aws_iam_policy.codepipeline.*.arn)
  role       = join("", aws_iam_role.codepipeline_role.*.id)
}
