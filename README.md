# Terraform on docker template

Execute `terraform` commands inside a container to have a predictable execution across multiple machines.

Uses an [S3](https://developer.hashicorp.com/terraform/language/settings/backends/s3) bucket to store the terraform state. There's no need to use a shared backend configuration if we're a one-person team.

1. Create the required S3 bucket and DynamoDB table (with `LockID` as  partition key).

2. Create an IAM user and start a subshell using [aws-vault](https://github.com/99designs/aws-vault/tree/master?tab=readme-ov-file#quick-start). The required permissions for this user are listed on the [S3 backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3) configuration docs.

`aws-vault exec javier --duration=2h`

3. Initialize terraform, if it hasn't been initialized yet, by runing:

```bash
podman run --rm -v "./deploy:/infra" -w "/infra" \
-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
-e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
hashicorp/terraform:1.6.6 init
```

3. Usually, `fmt` and `validate` commands are required on the developer machine and these don't need access to AWS credentials, so the following command could be used:

`podman run --rm -v "./deploy:/infra" -w "/infra" hashicorp/terraform:1.6.6 fmt`

4. For commands like `plan`, `apply` or `destroy` access to AWS credentials is required and they can be provided with the `-e` flag:

 ```bash
 podman run --rm -v "./deploy:/infra" -w "/infra" \
 -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
 -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
 -e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
 hashicorp/terraform:1.6.6 destroy -auto-approve
 ```

 These environment variables are set up in a sub-shell after running `aws-vault`.

Running these commands that change the terraform state should be run as part of a CI/CD pipeline and the frequency we have to run them locally should be minimal.

 Although not required, a docker compose file can be used to run `docker-compose -f deploy/docker-compose.yml run --rm terraform init` with the following content

```yaml
version: '3.7'
services:
  terraform:
    image: hashicorp/terraform:1.6.6
    volumes:
      - .:/infra
    working_dir: /infra
    environment:
      # These env-vars are set up temporarily by aws-vault
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
```
