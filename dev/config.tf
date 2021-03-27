terraform  {
    required_version = "0.14.7"
    backend "s3" {
        bucket    = "terraform.ninaite"
        key       = "development.terraform.tfstate"
        region    = "ap-northeast-1"
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "3.31.0"
        }
    }
}

provider "aws" {
    region = var.region
}

#cloudfront用のaloasを追加
provider "aws" {
    region  = "us-east-1"
    alias   = "virgnia"
}
