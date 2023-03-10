# pivate_s3_bucket

Creates an S3 bucket that can be only accessed by an EC2 instance with a specific instance profile

Use:

```
module "private_s3_bucket" {
    source = "github.com/kjenney/private_s3_bucket"
    bucket_name = "somerandombucketname"
    vpc_id = "vpc-01234567891011"
    subnet_id = "subnet-01234567891011"
}
```

## Test accessing the bucket

Once the AWS Instance is up and running you can connect with Session Manager and run:

```
aws s3 ls s3://somerandombucketname
```