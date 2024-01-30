# Terraform Start Stop Scheduler

This example module schedule instances to start at 8AM and stop at 8PM (Bangkok timezone) on Monday to Friday. Cloud functions can start and stop Compute Engine instance, GKE node pools and SQL instances in the project `scheduled_project_id` that specified in start and stop message.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project where resources will be created. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region in which resources will be applied. | `string` | n/a | yes |
| <a name="input_scheduled_project_id"></a> [scheduled\_project\_id](#input\_scheduled\_project\_id) | The project where resources will be scheduled start and stop. | `string` | n/a | yes |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

To provision this example, run the following from within this directory:

- `terraform init` to get the plugins.
- `terraform plan` to see the infrastructure plan.
- `terraform apply` to apply the infrastructure build.
- `terraform destroy` to destroy the built infrastructure.
