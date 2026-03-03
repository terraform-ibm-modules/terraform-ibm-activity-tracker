# Advanced example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=activity-tracker-advanced-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-activity-tracker/tree/main/examples/advanced"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->

<!-- There is a pre-commit hook that will take the title of each example add include it in the repos main README.md  -->
<!-- Add text below should describe exactly what resources are provisioned / configured by the example  -->

An end-to-end advanced example that will provision the following:

- A new resource group if one is not passed in.
- A new Cloud Logs instance.
- A new Key Protect instance with a root key.
- A new COS instance and KMS encrypted bucket.
- An Activity Tracker target for the new COS bucket, Cloud Logs instance and Event Streams instance.
- An Activity Tracker route for the above created targets.
- A CBR (Context-Based Restrictions) zone for the Activity Tracker Event Routing service, with CBR rules protecting all target services (Cloud Logs, Event Streams, and COS bucket) to restrict access to private endpoints only from the Activity Tracker service.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
