.PHONY: help list

help:
	@echo ""
	@echo "GenAI Tooling:"
	@echo "    make rules-generate        Generate AI agent rules files"
	@echo ""

list:
	@grep '^[^#[:space:]].*:' Makefile

.PHONY: rules-generate

rules-generate:
	rulesync generate --delete -f rules,ignore,skills -t agentsmd,agentsskills,claudecode,codexcli,opencode,cursor,copilot
