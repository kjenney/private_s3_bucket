module "private_s3_bucket" {
    source = "../../"
    vpc_id = "vpc-01234567891011"
    subnet_id = "subnet-01234567891011"
    external_role_id = "ARO1242432155242323"
}