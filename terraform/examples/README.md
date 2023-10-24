# Terraform Start Stop Scheduler

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | The project ID to host resources | `string` | n/a | yes |
| region | The region to host resources | `string` | n/a | yes |
| scheduled\_project\_id | The project ID where resources will be scheduled start and stop. | `string` | n/a | yes |

To provision this example, run the following from within this directory:

- `terraform init` to get the plugins.
- `terraform plan` to see the infrastructure plan.
- `terraform apply` to apply the infrastructure build.
- `terraform destroy` to destroy the built infrastructure.
