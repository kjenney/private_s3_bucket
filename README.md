# pivate_s3_bucket

Creates an S3 bucket that can be accessed by an IAM role in the same account and an IAM role or user in another account.

Use:

```
module "private_s3_bucket" {
    source = "../../"
    external_arn = "arn:aws:iam::111111111111:role/crossrole"
    external_id = "AROAEXAMPLEID"
    internal_user_id = "AIDAEXAMPLEID"
}
```

Where external_arn and external_id is an IAM role or user in a different account than the bucket that you'd like to use to access the newly created bucket.

External ID can get retrieved by using either `RoleId` with `aws iam get-role` or `UserId` with `aws iam get-user`.

You an optionally set the bucket name with variable `bucket_name`.

## Test accessing the bucket

Get the bucket name by running: `terraform output`.

Once the AWS Instance is up and running you can connect with Session Manager and run:

```
aws s3 ls s3://$bucketnamefromterraformoutput
```