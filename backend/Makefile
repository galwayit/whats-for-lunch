# Lunch backend tasks. Requires deno (2.x) and, for deploy, the Supabase CLI.
DENO ?= deno
SUPABASE ?= supabase
FUNCTIONS_DIR := supabase/functions
FUNCTIONS := places-nearby places-details places-photo ai-config ai-recommend groups-create \
  groups-propose groups-confirm groups-cancel groups-update groups-suggestions invitations invitations-respond invitations-suggest push-register \
  revenuecat-webhook account-delete groups-safety

.PHONY: check fmt test deploy deploy-db deploy-functions secrets help

help:
	@echo "make check            deno check + fmt --check on every function and shared module"
	@echo "make fmt              rewrite files with deno fmt"
	@echo "make test             deno test (pure modules, no network)"
	@echo "make deploy           db push + deploy every function (needs a linked project)"
	@echo "make secrets          push secrets from supabase/.env (never committed)"

check:
	cd $(FUNCTIONS_DIR) && $(DENO) fmt --check
	cd $(FUNCTIONS_DIR) && $(DENO) check $$(find . -name '*.ts' | sort)

fmt:
	cd $(FUNCTIONS_DIR) && $(DENO) fmt

test:
	cd $(FUNCTIONS_DIR) && $(DENO) test .

# --- deployment (documented in README.md; not run by CI) ---
deploy: deploy-db deploy-functions

deploy-db:
	$(SUPABASE) db push

deploy-functions:
	@for fn in $(FUNCTIONS); do \
		echo "deploying $$fn"; \
		$(SUPABASE) functions deploy $$fn || exit 1; \
	done

secrets:
	$(SUPABASE) secrets set --env-file supabase/.env
