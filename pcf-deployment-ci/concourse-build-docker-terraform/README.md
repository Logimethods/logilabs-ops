# Concourse-Build-Docker-Image
Build Terraform docker using the following command:
fly -t igor-team set-pipeline -p docker -c ci/pipeline.yml -l ci/credentials.yml
