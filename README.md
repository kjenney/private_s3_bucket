# pivate_s3_bucket

Creates an S3 bucket that can be only accessed by an EC2 instance with a specific instance profile

Use:

```
module "private_s3_bucket" {
    source = "../../"
    vpc_id = "vpc-01234567891011"
    subnet_id = "subnet-01234567891011"
    external_role_id = "ARO1242432155242323"
}
```

Where external_role_id is an IAM role in any account that you'd like to use to access the newly created bucket.

You an optionally set the bucket name with variable `bucket_name`.

## Test accessing the bucket

Get the bucket name by running: `terraform output`.

Once the AWS Instance is up and running you can connect with Session Manager and run:

```
aws s3 ls s3://$bucketnamefromterraformoutput
```