// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

// Use existing resource group
const resourceGroup = "geretain-test-resources"
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"
const fullyConfigurableTerraformDir = "solutions/fully-configurable"
const AccountSettingsDADir = "solutions/event-routing-account-settings"

var validRegions = []string{
	"in-che",
	"au-syd",
	"br-sao",
	"ca-tor",
	"eu-de",
	"eu-gb",
	"eu-es",
	"jp-osa",
	"jp-tok",
	"us-south",
	"us-east",
}
var IgnoreUpdates = []string{
	"module.account_routing_settings.ibm_atracker_settings.atracker_settings[0]",
}

var permanentResources map[string]interface{}

func TestMain(m *testing.M) {

	// Read the YAML file contents
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func setupexistingOptions(t *testing.T, cloudLogsPrefix string) (preReqTfOptions *terraform.Options, err error) {

	realTerraformDir := "./resources"
	tempTerraformDir, tempCopyErr := files.CopyTerraformFolderToTemp(realTerraformDir, cloudLogsPrefix)
	require.NoError(t, tempCopyErr, fmt.Sprintf("error copying resources to temp folder: %s", tempCopyErr))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")
	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix": cloudLogsPrefix,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, cloudLogsPrefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of pre-req resources failed")
		return existingTerraformOptions, existErr
	}

	return existingTerraformOptions, nil

}

func TestFullyConfigurableInSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "at-fc",
		Region:  "eu-de", // Hardcoding region to avoid jp-osa, as jp-osa does not support COS association with HPCS.
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableTerraformDir + "/*.tf",
		},
		ResourceGroup:          resourceGroup,
		TemplateFolder:         fullyConfigurableTerraformDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	cloudLogsPrefix := fmt.Sprintf("cloud-logs-%s", strings.ToLower(random.UniqueId()))

	existingTerraformOptions, err := setupexistingOptions(t, cloudLogsPrefix)

	if err != nil {
		assert.True(t, err == nil, "cloud logs instance creation failed")
		return
	}

	// Do not destroy pre-req resources if "DO_NOT_DESTROY_ON_FAILURE" is true
	defer func() {
		// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
		envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")

		// Do not destroy if tests failed and "DO_NOT_DESTROY_ON_FAILURE" is true
		if options.Testing.Failed() && strings.ToLower(envVal) == "true" {
			fmt.Println("Terratest failed. Debug the Test and delete resources manually.")
		} else {
			logger.Log(t, "START: Destroy (pre-req resources)")
			terraform.Destroy(t, existingTerraformOptions)
			terraform.WorkspaceDelete(t, existingTerraformOptions, cloudLogsPrefix)
			logger.Log(t, "END: Destroy (pre-req resources)")
		}
	}()
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
		{Name: "existing_cloud_logs_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "icl_crn"), DataType: "string"},
		{Name: "kms_encryption_enabled_buckets", Value: true, DataType: "bool"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "region", Value: options.Region, DataType: "string"},
	}

	err = options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestFullyConfigurableUpgradeInSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "at-fc-upg",
		Region:  "eu-de", // Hardcoding region to avoid jp-osa, as jp-osa does not support COS association with HPCS.
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableTerraformDir + "/*.tf",
		},
		ResourceGroup:          resourceGroup,
		TemplateFolder:         fullyConfigurableTerraformDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	cloudLogsPrefix := fmt.Sprintf("cloud-logs-%s", strings.ToLower(random.UniqueId()))

	existingTerraformOptions, err := setupexistingOptions(t, cloudLogsPrefix)

	if err != nil {
		assert.True(t, err == nil, "cloud logs instance creation failed")
		return
	}

	// Do not destroy pre-req resources if "DO_NOT_DESTROY_ON_FAILURE" is true
	defer func() {
		// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
		envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")

		// Do not destroy if tests failed and "DO_NOT_DESTROY_ON_FAILURE" is true
		if options.Testing.Failed() && strings.ToLower(envVal) == "true" {
			fmt.Println("Terratest failed. Debug the Test and delete resources manually.")
		} else {
			logger.Log(t, "START: Destroy (pre-req resources)")
			terraform.Destroy(t, existingTerraformOptions)
			terraform.WorkspaceDelete(t, existingTerraformOptions, cloudLogsPrefix)
			logger.Log(t, "END: Destroy (pre-req resources)")
		}
	}()

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
		{Name: "existing_cloud_logs_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "icl_crn"), DataType: "string"},
		{Name: "kms_encryption_enabled_buckets", Value: true, DataType: "bool"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "region", Value: options.Region, DataType: "string"},
	}

	err = options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

func TestRunAccountSettings(t *testing.T) {
	t.Parallel()

	region := validRegions[rand.Intn(len(validRegions))]
	prefix := "er"

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Region:  region,
		Prefix:  prefix,
		TarIncludePatterns: []string{
			"*.tf",
			"modules/metrics_routing" + "/*.tf",
			AccountSettingsDADir + "/*.tf",
		},
		TemplateFolder:         AccountSettingsDADir,
		Tags:                   []string{"er-da-test"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: IgnoreUpdates,
		},
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "primary_metadata_region", Value: "eu-de", DataType: "string"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}
