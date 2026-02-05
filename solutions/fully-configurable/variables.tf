########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "ibmcloud_cos_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a Cloud Object Storage (COS) instance. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the COS instance is in an account that's different from the one associated Observability resources. Leave empty if the same account owns all the instances."
  sensitive   = true
  default     = null
}

variable "ibmcloud_kms_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a root key and key ring in the key management service (KMS) instance. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the instance in `existing_kms_instance_crn` is in an account that's different from the Observability resources. Leave empty if the same account owns all the instances."
  sensitive   = true
  default     = null
}

variable "region" {
  type        = string
  description = "The region to provision all resources in. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/region) about how to select different regions for different services."
  default     = "us-south"
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to null or an empty string. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}


variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  # Defaulting this to public to workaround https://github.com/IBM-Cloud/terraform-provider-ibm/issues/5977
  default = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

##############################################################################
# IBM Cloud Logs
##############################################################################

variable "existing_cloud_logs_instance_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an existing Cloud Logs instance. This value is required and cannot be null if `enable_activity_tracker_event_routing_to_cloud_logs` is set to true."
}


##############################################################################
# Activity Tracker Event Routing Variables
##############################################################################

variable "enable_activity_tracker_event_routing_to_cos_bucket" {
  type        = bool
  description = "When set to `true`, you must provide a value for `existing_cos_instance_crn` to enable event routing from Activity Tracker to a Object Storage bucket."
  default     = false

  validation {
    condition     = var.enable_activity_tracker_event_routing_to_cos_bucket ? var.existing_cos_instance_crn != null : true
    error_message = "If 'enable_activity_tracker_event_routing_to_cos_bucket' is set to true, you must provide a value for 'existing_cos_instance_crn'."
  }

  validation {
    condition     = var.enable_activity_tracker_event_routing_to_cos_bucket || var.enable_activity_tracker_event_routing_to_cloud_logs
    error_message = "At least one of 'enable_activity_tracker_event_routing_to_cos_bucket' or 'enable_activity_tracker_event_routing_to_cloud_logs' must be true to route audit events to COS bucket or Cloud Logs instance."
  }

}

variable "enable_activity_tracker_event_routing_to_cloud_logs" {
  type        = bool
  description = "When set to `true`, you must provide a value for `existing_cloud_logs_instance_crn` to enable event routing from Activity Tracker to a Cloud Logs instance."
  default     = false

  validation {
    condition     = var.enable_activity_tracker_event_routing_to_cloud_logs ? var.existing_cloud_logs_instance_crn != null : true
    error_message = "If 'enable_activity_tracker_event_routing_to_cloud_logs' is set to true, you must provide a value for 'existing_cloud_logs_instance_crn'."
  }
}

variable "cos_target_name" {
  type        = string
  description = "Name of the cos target for activity tracker event routing."
  default     = null
}

variable "cloud_logs_target_name" {
  type        = string
  description = "Name of the cloud logs target for activity tracker event routing."
  default     = null
}

variable "activity_tracker_cos_route_name" {
  type        = string
  description = "Name of the cos route for activity tracker event routing."
  default     = null
}

variable "activity_tracker_cloud_logs_route_name" {
  type        = string
  description = "Name of the cloud logs route for activity tracker event routing."
  default     = null
}


########################################################################################################################
# COS variables
########################################################################################################################

variable "add_bucket_name_suffix" {
  type        = bool
  description = "Add a randomly generated suffix that is 4 characters in length, to the name of the newly provisioned Cloud Object Storage bucket. Do not use this suffix if you are passing the existing Cloud Object Storage bucket. To manage the name of the Cloud Object Storage bucket manually, use the `activity_tracker_cos_target_bucket_name` variable."
  default     = true
}

variable "cos_region" {
  type        = string
  default     = null
  description = "The Cloud Object Storage region. If no value is provided, the value that is specified in the `region` input variable is used."
}


variable "activity_tracker_cos_bucket_retention_policy" {
  type = object({
    default   = optional(number, 90)
    maximum   = optional(number, 350)
    minimum   = optional(number, 90)
    permanent = optional(bool, false)
  })
  description = "The retention policy of the IBM Cloud Activity Tracker Event Routing COS target bucket. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-activity-tracker/blob/main/solutions/fully-configurable/DA-types.md#activity_tracker_cos_bucket_retention_policy-)"
  default     = null
}


variable "activity_tracker_cos_target_bucket_name" {
  type        = string
  default     = "at-events-cos-bucket"
  description = "The name of the Cloud Object Storage bucket to create for the Cloud Object Storage target to store AT events. Cloud Object Storage bucket names are globally unique. If the `add_bucket_name_suffix` variable is set to `true`, 4 random characters are added to this name to ensure that the name of the bucket is globally unique. If the prefix input variable is passed, the name of the instance is prefixed to the value in the `<prefix>-value` format."
}


variable "activity_tracker_cos_bucket_access_tags" {
  type        = list(string)
  default     = []
  description = "A list of optional access tags to add to the IBM Cloud Activity Tracker Event Routing Cloud Object Storage bucket."
}


variable "activity_tracker_cos_target_bucket_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned Cloud Object Storage bucket. Specify one of the following values for the storage class: `standard`, `vault`, `cold`, `smart` (default), or `onerate_active`."
  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.activity_tracker_cos_target_bucket_class)
    error_message = "Specify one of the following values for the `cos_bucket_class`:  `standard`, `vault`, `cold`, `smart`, or `onerate_active`."
  }
}

variable "existing_cos_instance_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an existing Cloud Object Storage instance. This value is required and cannot be null if `enable_activity_tracker_event_routing_to_cos_bucket` is set to true."
}


variable "existing_activity_tracker_cos_target_bucket_name" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing bucket within the Cloud Object Storage instance in which to store IBM Cloud Activity Tracker Event Routing. If an existing Cloud Object Storage bucket is not specified, a bucket is created."
}

variable "existing_activity_tracker_cos_target_bucket_endpoint" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing Cloud Object Storage bucket endpoint to use for setting up IBM Cloud Activity Tracker Event Routing. If an existing endpoint is not specified, the endpoint of the new Cloud Object Storage bucket is used."
}

variable "skip_cos_kms_auth_policy" {
  type        = bool
  description = "To skip creating an IAM authorization policy that allows the Cloud Object Storage instance to read the encryption key from the key management service (KMS) instance, set this variable to `true`. Before you can create an encrypted Cloud Object Storage bucket, an authorization policy must exist."
  default     = false
}


variable "skip_activity_tracker_cos_auth_policy" {
  type        = bool
  description = "To skip creating an IAM authorization policy that allows the Activity Tracker to write to the Cloud Object Storage instance, set this variable to `true`."
  default     = false
}

variable "management_endpoint_type_for_bucket" {
  description = "The type of endpoint for the IBM Terraform provider to use to manage Cloud Object Storage buckets (`public`, `private`, or `direct`). If you are using a private endpoint, make sure that you enable virtual routing and forwarding (VRF) in your account, and that the Terraform runtime can access the IBM Cloud Private network."
  type        = string
  default     = "direct"
  validation {
    condition     = contains(["public", "private", "direct"], var.management_endpoint_type_for_bucket)
    error_message = "The specified `management_endpoint_type_for_bucket` is not valid. Specify a valid type of endpoint for the IBM Terraform provider to use to manage Cloud Object Storage buckets."
  }
}

variable "existing_monitoring_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an IBM Cloud Monitoring instance to to send IBM Cloud Logs buckets metrics to. If no value passed, metrics are sent to the instance associated to the container's location unless otherwise specified in the Metrics Router service configuration. Applies only if `existing_activity_tracker_cos_target_bucket_name` is not provided."
}

########################################################################################################################
# KMS variables
########################################################################################################################

variable "kms_encryption_enabled_buckets" {
  description = "Set to true to enable KMS encryption on the Object Storage buckets created for the Activity tracker events storage. When set to true, a value must be passed for either `existing_cos_kms_key_crn` or `existing_kms_instance_crn` (to create a new key)."
  type        = bool
  default     = false
  nullable    = false


  validation {
    condition     = var.existing_kms_instance_crn != null ? var.kms_encryption_enabled_buckets : true
    error_message = "If passing a value for 'existing_kms_instance_crn', you should set 'kms_encryption_enabled_buckets' to true."
  }

  validation {
    condition     = var.existing_cos_kms_key_crn != null ? var.kms_encryption_enabled_buckets : true
    error_message = "If passing a value for 'existing_cos_kms_key_crn', you should set 'kms_encryption_enabled_buckets' to true."
  }

  validation {
    condition     = var.kms_encryption_enabled_buckets ? ((var.existing_cos_kms_key_crn != null || var.existing_kms_instance_crn != null) ? true : false) : true
    error_message = "Either 'existing_cos_kms_key_crn' or 'existing_kms_instance_crn' is required if 'kms_encryption_enabled_buckets' is set to true."
  }
}
variable "existing_kms_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of the key management service (KMS) that is used to create keys for encrypting the Cloud Object Storage bucket. If you are not using an existing KMS root key, you must specify this CRN. If the existing Cloud Object Storage bucket details are passed as an input, this value is not required."
  validation {
    condition = anytrue([
      can(regex("^crn:(.*:){3}(kms|hs-crypto):(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_kms_instance_crn)),
      var.existing_kms_instance_crn == null,
    ])
    error_message = "The provided KMS instance CRN in the input 'existing_kms_instance_crn' in not valid."
  }
}

variable "existing_cos_kms_key_crn" {
  type        = string
  default     = null
  description = "Optional. The CRN of an existing key management service (KMS) key to use to encrypt the Cloud Object Storage buckets that this solution creates. To create a key ring and key, pass a value for the `existing_kms_instance_crn` input variable. To use existing Cloud Object Storage buckets, pass a value for `existing_activity_tracker_cos_target_bucket_name` input variables."
}

variable "kms_endpoint_type" {
  type        = string
  description = "The type of endpoint to use for communicating with the Key Protect or Hyper Protect Crypto Services instance. Possible values: `public`, `private`. Applies only if `existing_cos_kms_key_crn` is not specified."
  default     = "private"
  validation {
    condition     = can(regex("^(public|private)$", var.kms_endpoint_type))
    error_message = "Valid values for the `kms_endpoint_type_value` are `public` or `private`. "
  }
}

variable "cos_key_ring_name" {
  type        = string
  default     = "at-cos-key-ring"
  description = "The name of the key ring to create for the Cloud Object Storage bucket. If an existing key is used, this variable is not required. If the prefix input variable is passed, the name of the key ring is prefixed to the value in the `prefix-value` format."
}

variable "cos_key_name" {
  type        = string
  default     = "at-cos-key"
  description = "The name of the key to create for encrypting the Cloud Object Storage bucket. If an existing key is used, this variable is not required. If the prefix input variable is passed, the name of the key is prefixed to the value in the `prefix-value` format."
}

##############################################################
# Context-based restriction (CBR)
##############################################################

variable "cbr_rules" {
  type = list(object({
    description = string
    account_id  = string
    rule_contexts = list(object({
      attributes = optional(list(object({
        name  = string
        value = string
    }))) }))
    enforcement_mode = string
    operations = optional(list(object({
      api_types = list(object({
        api_type_id = string
      }))
    })))
  }))
  description = "(Optional, list) List of CBR rules to create. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-activity-tracker/blob/main/solutions/fully-configurable/DA-cbr_rules.md)"
  default     = []
  # Validation happens in the rule module
}
