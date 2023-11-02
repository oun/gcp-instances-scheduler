# Terraform Start Stop Scheduler

This example module schedule instances to start at 8AM and stop at 8PM (Bangkok timezone) on Monday to Friday. Cloud functions can start and stop Compute Engine instance, GKE node pools and SQL instances in the project `scheduled_project_id` that specified in start and stop message.

## Inputs

| Name                 | Description                                                      | Type     | Default | Required |
| -------------------- | ---------------------------------------------------------------- | -------- | ------- | :------: |
| project_id           | The project ID to host resources.                                | `string` | n/a     |   yes    |
| region               | The region to host resources.                                    | `string` | n/a     |   yes    |
| scheduled_project_id | The project ID where resources will be scheduled start and stop. | `string` | n/a     |   yes    |

To provision this example, run the following from within this directory:

- `terraform init` to get the plugins.
- `terraform plan` to see the infrastructure plan.
- `terraform apply` to apply the infrastructure build.
- `terraform destroy` to destroy the built infrastructure.
