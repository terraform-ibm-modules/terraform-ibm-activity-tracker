#!/bin/bash

############################################################################################################
## This script is used by the catalog pipeline to deploy the Cloud Logs instance
## which are the prerequisites for the fully-configurable AT Event Routing DA.
############################################################################################################

set -e

DA_DIR="solutions/fully-configurable"
TERRAFORM_SOURCE_DIR="tests/resources"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"
TF_VARS_FILE="terraform.tfvars"

(
  cwd=$(pwd)
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Provisioning pre-requisite Cloud Logs instance .."
  terraform init || exit 1

  # $VALIDATION_APIKEY is available in the catalog runtime
  {
    echo "ibmcloud_api_key=\"${VALIDATION_APIKEY}\""
    echo "prefix=\"at-$(openssl rand -hex 2)\""
  } >> ${TF_VARS_FILE}
  terraform apply -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  existing_cloud_logs_instance_crn="existing_cloud_logs_instance_crn"
  existing_cloud_logs_instance_value=$(terraform output -state=terraform.tfstate -raw icl_crn)

  echo "Appending '${existing_cloud_logs_instance_crn}' input variable values to ${JSON_FILE}.."

  cd "${cwd}"
  jq -r --arg existing_cloud_logs_instance_crn "${existing_cloud_logs_instance_crn}" \
        --arg existing_cloud_logs_instance_value "${existing_cloud_logs_instance_value}" \
        '. + {($existing_cloud_logs_instance_crn): $existing_cloud_logs_instance_value}' "${JSON_FILE}" > tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation completed successfully."
)
