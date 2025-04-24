# IBM Cloud Activity Tracker Event Routing

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-activity-tracker?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-activity-tracker/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)

This module supports configuring an IBM Cloud Activity Tracker event routing target, routes and settings.

<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-activity-tracker](#terraform-ibm-activity-tracker)
* [Examples](./examples)
    * [Advanced example](./examples/advanced)
    * [Basic example](./examples/basic)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

<!--
If this repo contains any reference architectures, uncomment the heading below and link to them.
(Usually in the `/reference-architectures` directory.)
See "Reference architecture" in the public documentation at
https://terraform-ibm-modules.github.io/documentation/#/implementation-guidelines?id=reference-architecture
-->
<!-- ## Reference architectures -->

<!-- Replace this heading with the name of the root level module (the repo name) -->
## terraform-ibm-activity-tracker

### Usage

```hcl
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "X.Y.Z"  # Lock into a provider version that satisfies the module constraints
    }
  }
}

locals {
    region = "us-south"
    target_ids = [
    module.activity_tracker.activity_tracker_targets["icl-target"].id,
    module.activity_tracker.activity_tracker_targets["cos-target"].id,
    module.activity_tracker.activity_tracker_targets["es-target"].id
  ]
}

provider "ibm" {
  ibmcloud_api_key = "XXXXXXXXXX"  # replace with apikey value
  region           = local.region
}

module "activity_tracker" {
  source            = "terraform-ibm-modules/activity-tracker/ibm"
  version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release

  # Cloud Logs target
  cloud_logs_targets = [
    {
      instance_id   = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
      target_region = local.region
      target_name   = "icl-target"
    }
  ]

  # COS target
  cos_targets = [
    {
      bucket_name                       = "cos-bucket"
      endpoint                          = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
      instance_id                       = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
      target_region                     = local.region
      target_name                       = "cos-target"
      skip_atracker_cos_iam_auth_policy = false
      service_to_service_enabled        = true
    }
  ]

  # Event Stream target
  eventstreams_targets = [
    {
      instance_id                      = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
      brokers                          = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
      topic                            = "es-topic"
      target_region                    = local.region
      target_name                      = "es-target"
      service_to_service_enabled       = true
      skip_atracker_es_iam_auth_policy = false
    }
  ]

  # AT Event routing route
  activity_tracker_routes = [
    {
      locations  = ["*", "global"]
      target_ids = local.target_ids
      route_name = "at-route"
    }
  ]
}
```

### Required access policies

<!-- PERMISSIONS REQUIRED TO RUN MODULE
If this module requires permissions, uncomment the following block and update
the sample permissions, following the format.
Replace the 'Sample IBM Cloud' service and roles with applicable values.
The required information can usually be found in the services official
IBM Cloud documentation.
To view all available service permissions, you can go in the
console at Manage > Access (IAM) > Access groups and click into an existing group
(or create a new one) and in the 'Access' tab click 'Assign access'.
-->

<!--
You need the following permissions to run this module:

- Service
    - **Resource group only**
        - `Viewer` access on the specific resource group
    - **Sample IBM Cloud** service
        - `Editor` platform access
        - `Manager` service access
-->

<!-- NO PERMISSIONS FOR MODULE
If no permissions are required for the module, uncomment the following
statement instead the previous block.
-->

<!-- No permissions are needed to run this module.-->

<!-- The following content is automatically populated by the pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.76.0, < 2.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1, < 1.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [ibm_atracker_route.atracker_routes](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/atracker_route) | resource |
| [ibm_atracker_settings.atracker_settings](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/atracker_settings) | resource |
| [ibm_atracker_target.atracker_cloud_logs_targets](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/atracker_target) | resource |
| [ibm_atracker_target.atracker_cos_targets](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/atracker_target) | resource |
| [ibm_atracker_target.atracker_eventstreams_targets](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/atracker_target) | resource |
| [ibm_iam_authorization_policy.atracker_cloud_logs](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_iam_authorization_policy.atracker_cos](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_iam_authorization_policy.atracker_es](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [time_sleep.wait_for_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_cloud_logs_auth_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_event_stream_auth_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_activity_tracker_routes"></a> [activity\_tracker\_routes](#input\_activity\_tracker\_routes) | List of routes to be created, maximum four routes are allowed | <pre>list(object({<br/>    locations  = list(string)<br/>    target_ids = list(string)<br/>    route_name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_cloud_logs_targets"></a> [cloud\_logs\_targets](#input\_cloud\_logs\_targets) | List of Cloud Logs targets to be created | <pre>list(object({<br/>    instance_id                              = string<br/>    target_region                            = optional(string)<br/>    target_name                              = string<br/>    skip_atracker_cloud_logs_iam_auth_policy = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_cos_targets"></a> [cos\_targets](#input\_cos\_targets) | List of Cloud Object Storage targets to be created | <pre>list(object({<br/>    endpoint                          = string<br/>    bucket_name                       = string<br/>    instance_id                       = string<br/>    api_key                           = optional(string)<br/>    service_to_service_enabled        = optional(bool, true)<br/>    target_region                     = optional(string)<br/>    target_name                       = string<br/>    skip_atracker_cos_iam_auth_policy = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_eventstreams_targets"></a> [eventstreams\_targets](#input\_eventstreams\_targets) | List of Event Streams targets to be created | <pre>list(object({<br/>    instance_id                      = string<br/>    brokers                          = list(string)<br/>    topic                            = string<br/>    api_key                          = optional(string)<br/>    service_to_service_enabled       = optional(bool, true)<br/>    target_region                    = optional(string)<br/>    target_name                      = string<br/>    skip_atracker_es_iam_auth_policy = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_global_event_routing_settings"></a> [global\_event\_routing\_settings](#input\_global\_event\_routing\_settings) | Global account settings for event routing. [Learn more](https://cloud.ibm.com/docs/atracker?topic=atracker-settings&interface=ui) | <pre>object({<br/>    default_targets           = optional(list(string), [])<br/>    metadata_region_primary   = string<br/>    metadata_region_backup    = optional(string)<br/>    permitted_target_regions  = list(string)<br/>    private_api_endpoint_only = optional(bool, false)<br/>  })</pre> | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_activity_tracker_routes"></a> [activity\_tracker\_routes](#output\_activity\_tracker\_routes) | The map of created routes |
| <a name="output_activity_tracker_settings"></a> [activity\_tracker\_settings](#output\_activity\_tracker\_settings) | AT event routing account global settings. |
| <a name="output_activity_tracker_targets"></a> [activity\_tracker\_targets](#output\_activity\_tracker\_targets) | The map of created targets |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set-up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
