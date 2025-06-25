# Configuring complex inputs for Cloud Automation for Observability

* Activity Tracker Event Routing COS bucket retention policy (`at_cos_bucket_retention_policy`)

## at_cos_bucket_retention_policy <a name="at_cos_bucket_retention_policy"></a>

The `at_cos_bucket_retention_policy` input variable allows you to provide the retention policy of the IBM Cloud Activity Tracker Event Routing COS target bucket that will be configured. Refer [here](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-immutable) for more information.

* Variable name: `at_cos_bucket_retention_policy`.
* Type: An object representing a retention policy.
* Default value: null (`null`).

### Options for at_cos_bucket_retention_policy

* `default` (optional): The number of days that an object can remain unmodified in an Object Storage bucket.
* `maximum` (optional): The maximum number of days that an object can be kept unmodified in the bucket.
* `minimum` (optional): The minimum number of days that an object must be kept unmodified in the bucket.
* `permanent` (optional): Whether permanent retention status is enabled for the Object Storage bucket.

### Example at_cos_bucket_retention_policy

```hcl
{
    default   = 90
    maximum   = 350
    minimum   = 90
    permanent = false
}
```