Due to a limitation in Terraform dependency graph for providers initialization (see this long lasting [issue](https://github.com/hashicorp/terraform/issues/2430)) it is required to have the following environement variables defined (even if they are dummy one and overridden during the script execution) : `AWS_ACCESS_KEY_ID`  and `AWS_SECRET_ACCESS_KEY`

If they are not already defined you can use the following:

```bash
export AWS_ACCESS_KEY_ID="no_need_to_define_an_access_key"  
export AWS_SECRET_ACCESS_KEY="no_need_to_define_a_secret_key"


