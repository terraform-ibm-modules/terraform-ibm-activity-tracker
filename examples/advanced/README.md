# Advanced example

<!-- There is a pre-commit hook that will take the title of each example add include it in the repos main README.md  -->
<!-- Add text below should describe exactly what resources are provisioned / configured by the example  -->

An end-to-end advanced example that will provision the following:
- A new resource group if one is not passed in.
- A new Cloud Logs instance.
- A new Key Protect instance with a root key.
- A new COS instance and KMS encrypted bucket.
- An Activity Tracker target for the new COS bucket, Cloud Logs instance and Event Streams instance.
- And Activity Tracker route for the above created targets.
