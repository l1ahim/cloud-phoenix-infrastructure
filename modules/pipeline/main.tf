data "aws_caller_identity" "default" {}

data "aws_region" "default" {}

resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name              = "/${var.app_name}/codebuild"
  retention_in_days = 7
}

resource "aws_codebuild_source_credential" "codebuild_creds" {
  auth_type   = var.source_credential_auth_type
  server_type = var.source_credential_server_type
  token       = var.source_credential_token
}

resource "aws_codebuild_project" "ph_codebuild_project" {
    name = "${var.app_name}-project"
    description = "CodeBuild project for ${var.app_name} app"
    service_role = join("", aws_iam_role.codebuild_role.*.arn)
    badge_enabled = true
    build_timeout          = 60

    artifacts {
        type = "NO_ARTIFACTS"
    }

    cache {
        type     = "S3"
        location = aws_s3_bucket.codepipeline_bucket.bucket
    }

    environment {
        compute_type = "BUILD_GENERAL1_SMALL"
        image = "aws/codebuild/standard:3.0"
        type = "LINUX_CONTAINER"
        image_pull_credentials_type = "CODEBUILD"
        privileged_mode = true

        environment_variable {
            name = "DB_CONNECTION_STRING"
            value = var.db_connection_string
            type = "PARAMETER_STORE"
        }
        environment_variable {
            name = "IMAGE_REPO_NAME"
            value = "phoenix"
        }
        environment_variable {
            name = "IMAGE_TAG"
            value = "latest"
        }
    }

    logs_config {
        cloudwatch_logs {
            status = "ENABLED"
            group_name = aws_cloudwatch_log_group.codebuild_logs.name
            stream_name = "${var.app_name}_build"
        }
    }

    source {
        type = "GITHUB"
        location = var.github_repo
        git_clone_depth = 1
        buildspec = var.buildspec

        auth {
            type = "OAUTH"
            resource = aws_codebuild_source_credential.codebuild_creds.arn
        }
    }

    source_version = var.repo_source_version

    vpc_config {
        vpc_id = var.vpc_id
        subnets = var.private_subnets
        security_group_ids = var.security_group_ids
    }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
    bucket = "phoenix-codepipeline-bucket"
    force_destroy = true
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
    bucket = aws_s3_bucket.codepipeline_bucket.id
    acl    = "private"
}

### Codepipeline

resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "codepipeline" {

    name = "${var.app_name}-pipeline"
    role_arn = aws_iam_role.codepipeline_role.arn

    artifact_store {
        location = aws_s3_bucket.codepipeline_bucket.bucket
        type     = "S3"
    }

    stage {
        name = "Source"

        action {
            name = "Source"
            category = "Source"
            owner = "AWS"
            provider = "CodeStarSourceConnection"
            version = "1"
            output_artifacts = ["source_output"]

            configuration = {
                ConnectionArn = aws_codestarconnections_connection.github.arn
                FullRepositoryId = "l1ahim/cloud-phoenix-pipeline"
                BranchName = var.repo_source_version
            }
        }
    }

    stage {
        name = "Build"
        action {
            name = "Build"
            category = "Build"
            owner = "AWS"
            version = "1"
            provider = "CodeBuild"
            input_artifacts  = ["source_output"]
            output_artifacts = ["build_output"]

            configuration = {
                ProjectName = aws_codebuild_project.ph_codebuild_project.id
            }

        }
    }

    stage {
        name = "Deploy"
        action {
            name = "Deploy"
            category = "Deploy"
            owner = "AWS"
            provider = "ECS"
            version = "1"
            input_artifacts = ["build_output"]

            configuration = {
                ClusterName = var.app_name
                DeploymentTimeout = "30"
                ServiceName = "${var.app_name}-svc"
            }
        }
    }
}
