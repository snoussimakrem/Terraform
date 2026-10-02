# Named commands = documented commands. Uses RECIPEPREFIX so no tab pitfalls.
.RECIPEPREFIX = >
ENV    ?= dev
STACK  ?= 10-network
STACKS := 10-network 15-data-lake 20-cluster 30-platform 40-data-services
# MODE: local = LocalStack + kind (free) | aws = real AWS (may cost money!)
MODE   ?= local

.PHONY: up down bootstrap init plan apply destroy apply-all fmt validate lint scan policy test integration pin-actions

up:           ## start LocalStack
> docker compose up -d
down:         ## stop LocalStack and DELETE its data (also: kind delete cluster --name dp-dev)
> docker compose down -v
bootstrap:    ## create the remote-state bucket (local state, chicken-and-egg)
> ./scripts/stack.sh global state-bootstrap apply
init plan apply destroy:  ## e.g. make plan ENV=dev STACK=10-network
> MODE=$(MODE) ./scripts/stack.sh $(ENV) $(STACK) $@
apply-all:    ## apply every stack of ENV in dependency order
> for s in $(STACKS); do MODE=$(MODE) ./scripts/stack.sh $(ENV) $$s apply || exit 1; done
fmt:
> terraform fmt -recursive
validate:     ## init -backend=false + validate every module and stack
> ./scripts/validate-all.sh
lint:
> tflint --init && tflint --recursive
scan:
> trivy config . && checkov -d . --config-file .checkov.yml
policy:       ## OPA policies: unit tests, then against a real plan JSON
> conftest verify --policy policies/opa
> conftest test --policy policies/opa --all-namespaces $(ENV)-$(STACK).plan.json
test:         ## native terraform test (mock providers, no cloud)
> ./scripts/test-all.sh
integration:  ## Terratest against LocalStack (make up first)
> cd tests/integration && go test -v -timeout 20m ./...
pin-actions:  ## replace tag refs with full commit SHAs
> pinact run
