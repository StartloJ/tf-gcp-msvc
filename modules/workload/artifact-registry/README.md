<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.10, < 8 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 7.10, < 8 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 7.39.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | 7.39.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google-beta_google_artifact_registry_repository.repo](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_artifact_registry_repository) | resource |
| [google-beta_google_artifact_registry_vpcsc_config.repo_vpc_sc](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_artifact_registry_vpcsc_config) | resource |
| [google_artifact_registry_repository_iam_member.readers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_artifact_registry_repository_iam_member.writers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cleanup_policies"></a> [cleanup\_policies](#input\_cleanup\_policies) | Cleanup policies for this repository. Cleanup policies indicate when certain package versions can be automatically deleted. Map keys are policy IDs supplied by users during policy creation. They must unique within a repository and be under 128 characters in length. | <pre>map(object({<br/>    action = optional(string)<br/>    condition = optional(object({<br/>      tag_state             = optional(string)<br/>      tag_prefixes          = optional(list(string))<br/>      version_name_prefixes = optional(list(string))<br/>      package_name_prefixes = optional(list(string))<br/>      older_than            = optional(string)<br/>      newer_than            = optional(string)<br/>    }), null)<br/>    most_recent_versions = optional(object({<br/>      package_name_prefixes = optional(list(string))<br/>      keep_count            = optional(number)<br/>    }), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_cleanup_policy_dry_run"></a> [cleanup\_policy\_dry\_run](#input\_cleanup\_policy\_dry\_run) | If true, the cleanup pipeline is prevented from deleting versions in this repository | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | The user-provided description of the repository | `string` | `null` | no |
| <a name="input_docker_config"></a> [docker\_config](#input\_docker\_config) | Docker repository config contains repository level configuration for the repositories of docker type | <pre>object({<br/>    immutable_tags = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_enable_vpcsc_policy"></a> [enable\_vpcsc\_policy](#input\_enable\_vpcsc\_policy) | Enable VPC SC policy | `bool` | `false` | no |
| <a name="input_format"></a> [format](#input\_format) | The format of packages that are stored in the repository. You can only create alpha formats if you are a member of the alpha user group. | `string` | n/a | yes |
| <a name="input_kms_key_name"></a> [kms\_key\_name](#input\_kms\_key\_name) | The Cloud KMS resource name of the customer managed encryption key that’s used to encrypt the contents of the Repository. Has the form: projects/my-project/locations/my-region/keyRings/my-kr/cryptoKeys/my-key. This value may not be changed after the Repository has been created | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels for the repository | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | The name of the location this repository is located in | `string` | n/a | yes |
| <a name="input_maven_config"></a> [maven\_config](#input\_maven\_config) | MavenRepositoryConfig is maven related repository details. Provides additional configuration details for repositories of the maven format type. | <pre>object({<br/>    allow_snapshot_overwrites = optional(bool)<br/>    version_policy            = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_members"></a> [members](#input\_members) | Artifact Registry Reader and Writer roles for Users/SAs. Key names must be readers and/or writers | `map(list(string))` | `{}` | no |
| <a name="input_mode"></a> [mode](#input\_mode) | The mode configures the repository to serve artifacts from different sources. Default value is STANDARD\_REPOSITORY. Possible values are: STANDARD\_REPOSITORY, VIRTUAL\_REPOSITORY, REMOTE\_REPOSITORY | `string` | `"STANDARD_REPOSITORY"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID to create the repository | `string` | n/a | yes |
| <a name="input_remote_repository_config"></a> [remote\_repository\_config](#input\_remote\_repository\_config) | Configuration specific for a Remote Repository. | <pre>object({<br/>    description                 = optional(string)<br/>    disable_upstream_validation = optional(bool, true)<br/>    upstream_credentials = optional(object({<br/>      username                = string<br/>      password_secret_version = string<br/>    }), null)<br/>    apt_repository = optional(object({<br/>      public_repository = optional(object({<br/>        repository_base = string<br/>        repository_path = string<br/>      }), null)<br/>    }), null)<br/>    docker_repository = optional(object({<br/>      public_repository = optional(string, "DOCKER_HUB")<br/>      custom_repository = optional(object({<br/>        uri = string<br/>      }), null)<br/>    }), null)<br/>    maven_repository = optional(object({<br/>      public_repository = optional(string, "MAVEN_CENTRAL")<br/>      custom_repository = optional(object({<br/>        uri = string<br/>      }), null)<br/>    }), null)<br/>    npm_repository = optional(object({<br/>      public_repository = optional(string, "NPMJS")<br/>      custom_repository = optional(object({<br/>        uri = string<br/>      }), null)<br/>    }), null)<br/>    python_repository = optional(object({<br/>      public_repository = optional(string, "PYPI")<br/>      custom_repository = optional(object({<br/>        uri = string<br/>      }), null)<br/>    }), null)<br/>    yum_repository = optional(object({<br/>      public_repository = optional(object({<br/>        repository_base = string<br/>        repository_path = string<br/>      }), null)<br/>    }), null)<br/>  })</pre> | `null` | no |
| <a name="input_repository_id"></a> [repository\_id](#input\_repository\_id) | The repository name | `string` | n/a | yes |
| <a name="input_virtual_repository_config"></a> [virtual\_repository\_config](#input\_virtual\_repository\_config) | Configuration specific for a Virtual Repository. | <pre>object({<br/>    upstream_policies = optional(list(object({<br/>      id         = string<br/>      repository = string<br/>      priority   = number<br/>    })), null)<br/>  })</pre> | `null` | no |
| <a name="input_vpcsc_policy"></a> [vpcsc\_policy](#input\_vpcsc\_policy) | The VPC SC policy for project and location. Possible values are: DENY, ALLOW | `string` | `"ALLOW"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_artifact_id"></a> [artifact\_id](#output\_artifact\_id) | an identifier for the resource |
| <a name="output_artifact_name"></a> [artifact\_name](#output\_artifact\_name) | an identifier for the resource |
| <a name="output_create_time"></a> [create\_time](#output\_create\_time) | The time when the repository was created. |
| <a name="output_update_time"></a> [update\_time](#output\_update\_time) | The time when the repository was last updated. |
<!-- END_TF_DOCS -->