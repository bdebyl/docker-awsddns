# Docker AWS DDNS

Dockerized script utilizing `aws` CLI for the usage of cron-based updating of
a desired hostname within a Zone.

[![Build Status](https://ci.bdebyl.net/api/badges/bdebyl/docker-awsddns/status.svg)](https://ci.bdebyl.net/bdebyl/docker-awsddns)

## Access Key

It's recommended to create a specific user in AWS IAM which is limited to a
subset of the Route53 service.

### Recommended Policy

```text
{
  "Version": "2012-10-17"
  "Statement": [
    {
      "Effect": Allow",
      "Action": [
        "route53:TestDNSAnswer",
        "route53:ChangeResourceRecordSets",
      ],
      "Resource": "*"
    }
  ]
}
```

## Usage

The default usage expects the following environment variables to be passed in
during `docker run` (or other):

| Environment Varialbe    | Description                                                                    |
|-------------------------|--------------------------------------------------------------------------------|
| `AWS_ZONE_ID`           | AWS Zone ID of the zone to be updated                                          |
| `AWS_ZONE_HOSTNAME`     | Record name (hostname) of the record to be updated (e.g. `myhome.example.org`) |
| `AWS_DEFAULT_REGION`    | AWS default region (e.g. `us-east-1`)                                          |
| `AWS_ACCESS_KEY_ID`     | AWS Access Key to be used (see Access Key notes)                               |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key to be used (see Access Key notes)                        |
