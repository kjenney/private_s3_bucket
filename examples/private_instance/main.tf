module "private_s3_bucket" {
    source = "../../"
    external_arn = "arn:aws:iam::111111111111:role/crossrole"
    external_id = "AROAEXAMPLEID"
    internal_user_id = "AIDAEXAMPLEID"
}