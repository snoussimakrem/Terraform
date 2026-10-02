package main

import rego.v1

# Resources that will exist after apply (create/update/no-op), excluding deletes.
managed(type) := [rc |
	some rc in input.resource_changes
	rc.type == type
	rc.mode == "managed"
	not "delete" in rc.change.actions
]
