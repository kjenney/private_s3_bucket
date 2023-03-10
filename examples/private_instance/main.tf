module "private_s3_bucket" {
    source = "../"
    bucket_name = "somerandombucketname"
    vpc_id = "vpc-01234567891011"
    subnet_id = "subnet-01234567891011"
}