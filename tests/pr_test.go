// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"log"
	"math/rand"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

// Use existing resource group
const resourceGroup = "geretain-test-resources"
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"
const fullyConfigurableTerraformDir = "solutions/fully-configurable"

var validRegions = []string{
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

func TestFullyConfigurableInSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "at-fc",
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

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "existing_resource_group_name", Value: "Default", DataType: "string"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
		{Name: "kms_encryption_enabled_buckets", Value: true, DataType: "bool"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "region", Value: validRegions[rand.Intn(len(validRegions))], DataType: "string"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestFullyConfigurableUpgradeInSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "at-fc-upg",
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

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "existing_resource_group_name", Value: "Default", DataType: "string"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
		{Name: "kms_encryption_enabled_buckets", Value: true, DataType: "bool"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "region", Value: validRegions[rand.Intn(len(validRegions))], DataType: "string"},
	}

	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

func setupAddonOptions(t *testing.T, prefix string) *testaddons.TestAddonOptions {
	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:       t,
		Prefix:        prefix,
		ResourceGroup: "geretain-vipin-rg",
	})

	return options
}

func TestRunTerraformAddon(t *testing.T) {
	t.Parallel()

	options := setupAddonOptions(t, "sac1")

	// Using the specialized Terraform helper function
	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,              // prefix for unique resource naming
		"deploy-arch-ibm-icd-redis", // offering name
		"Standard",                  // offering flavor
		map[string]interface{}{ // inputs
			"prefix":                    options.Prefix,
			"resource_group_name":       "geretain-vipin-rg",
			"existing_kms_instance_crn": "crn:v1:bluemix:public:hs-crypto:us-south:a/abac0df06b644a9cabc6e44f55b3880e:e6dce284-e80f-46e1-a3c1-830f7adff7a9::",
		},
	)

	err := options.RunAddonTest()
	assert.Nil(t, err, "This should not have errored")
}
