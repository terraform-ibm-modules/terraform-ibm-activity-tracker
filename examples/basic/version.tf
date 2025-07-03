terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.79.2" # Locking into 1.79.2 due to https://github.com/terraform-ibm-modules/terraform-ibm-activity-tracker/pull/43#issuecomment-3027718565
    }
  }
}
