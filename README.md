# Terraform at OVHcloud
This repository contains my unitary examples of terraform resources with multiples providers : OVH, Openstack and Hashicorp AWS to automate OVHcloud resource provisionning. 

I tried to diminish the number of pre requisites by creating the Openstack / S3 users from within the terraform scripts. 

## Pre requisites

The following environment variables need to be defined for the OVH provider :
* OVH_ENDPOINT
* OVH_APPLICATION_KEY
* OVH_APPLICATION_SECRET
* OVH_CONSUMER_KEY

The following env variable is required specifically for those scripts :
* TF_VAR_OVH_PUBLIC_CLOUD_PROJECT_ID : it shall be filled with your public cloud project id. If not filled, it will be requested on script startup.

If other pre requisites are needed for some use case, a specific README is present in the example folder.

## Folder structure
One folder per example. In order to run the example, you should go in the example subdirectory and run `terraform init` and `terraform apply`

# Notes/Disclaimer

* Those scripts do not follow terraform best practices to split the project in multiple files e.g. provider.tf, main.tf, variables.tf, outputs.tf, ... This has been done intentionnaly to avoid switching into multiples files for what are a really simple examples.
* The secret that is created by this script is stored in the [local](https://developer.hashicorp.com/terraform/language/settings/backends/local) state back-end. If you use this back-end in production, be sure to consider the state file as a secret. 

# License

Copyright 2022-2023 OVH SAS

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.