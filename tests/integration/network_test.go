package integration

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Integration test: REALLY applies the module (against LocalStack), asserts on outputs, then destroys.
// Unit tests (terraform test + mocks) prove the logic; this proves the provider accepts our config.
// Requires: `make up` (LocalStack on :4566).
func TestNetworkModuleAppliesAndDestroys(t *testing.T) {
	t.Parallel()

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./fixtures/network",
	})
	defer terraform.Destroy(t, opts) // always clean up, even when assertions fail

	terraform.InitAndApply(t, opts)

	vpcID := terraform.Output(t, opts, "vpc_id")
	assert.Regexp(t, "^vpc-", vpcID)

	private := terraform.OutputList(t, opts, "private_subnet_ids")
	assert.Len(t, private, 2)

	// Idempotency: a second plan must be empty. Non-empty = the module fights itself (drift bug).
	exit := terraform.PlanExitCode(t, opts)
	assert.Equal(t, 0, exit, "second plan should show no changes")
}
