# PubSub Cloud Function

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_available_memory"></a> [available\_memory](#input\_available\_memory) | The amount of memory allotted for the function to use. | `string` | `"256M"` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | The bucket to store function source code. | `string` | `""` | no |
| <a name="input_build_service_account_email"></a> [build\_service\_account\_email](#input\_build\_service\_account\_email) | The service account to be used for building container. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | The description of the cloud function. | `string` | `"Processes events."` | no |
| <a name="input_entry_point"></a> [entry\_point](#input\_entry\_point) | The name of a method in the function source which will be invoked when the function is executed. | `string` | n/a | yes |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | A set of key/value environment variable pairs to assign to the function. | `map(string)` | `{}` | no |
| <a name="input_function_labels"></a> [function\_labels](#input\_function\_labels) | A set of key/value label pairs to assign to the function. | `map(string)` | `{}` | no |
| <a name="input_ingress_settings"></a> [ingress\_settings](#input\_ingress\_settings) | The ingress settings for the function. | `string` | `"ALLOW_INTERNAL_ONLY"` | no |
| <a name="input_location"></a> [location](#input\_location) | The location of the cloud function. | `string` | n/a | yes |
| <a name="input_max_instance_count"></a> [max\_instance\_count](#input\_max\_instance\_count) | The limit on the maximum number of function instances that may coexist at a given time. | `number` | `1` | no |
| <a name="input_min_instance_count"></a> [min\_instance\_count](#input\_min\_instance\_count) | The limit on the minimum number of function instances that may coexist at a given time. | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the cloud function. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project where resources will be created. | `string` | n/a | yes |
| <a name="input_pubsub_filter"></a> [pubsub\_filter](#input\_pubsub\_filter) | PubSub subscription message filter. | <pre>object({<br>    attribute = string<br>    value     = string<br>  })</pre> | n/a | yes |
| <a name="input_pubsub_topic"></a> [pubsub\_topic](#input\_pubsub\_topic) | The name of a Pub/Sub topic. | `string` | n/a | yes |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The runtime in which the function will be executed. | `string` | `"nodejs18"` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The existing service account to run cloud function. | `string` | `""` | no |
| <a name="input_source_dir"></a> [source\_dir](#input\_source\_dir) | The pathname of the directory which contains the function source code. | `string` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The function execution timeout. | `number` | `540` | no |
| <a name="input_trigger_service_account_email"></a> [trigger\_service\_account\_email](#input\_trigger\_service\_account\_email) | Service account to use as the identity for the Eventarc trigger. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_location"></a> [location](#output\_location) | The location of the cloud function. |
| <a name="output_name"></a> [name](#output\_name) | The name of the cloud function. |
| <a name="output_project"></a> [project](#output\_project) | The project where resources will be created. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
