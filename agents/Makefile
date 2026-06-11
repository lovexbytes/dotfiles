SKILLS_SRC_ROOT := $(CURDIR)/skills
SKILL_MANIFESTS := $(wildcard $(SKILLS_SRC_ROOT)/*/SKILL.md)
SKILL_DIRS := $(patsubst %/SKILL.md,%,$(SKILL_MANIFESTS))
SKILL_NAMES := $(sort $(notdir $(SKILL_DIRS)))

INSTRUCTIONS_SRC := $(CURDIR)/instructions/assistant.md
INSTALL_HOME ?= /Users/lovexbytes
OPENCODE_SKILLS_ROOT := $(INSTALL_HOME)/.config/opencode/skills
OPENCODE_AGENTS := $(INSTALL_HOME)/.config/opencode/AGENTS.md
HERMES_SOUL := $(INSTALL_HOME)/.hermes/SOUL.md

.PHONY: list-skills install-opencode-skills install-opencode-instructions install-hermes-instructions install-opencode install-hermes install

list-skills:
	@set -- $(SKILL_NAMES); \
	for skill do \
		echo "$$skill"; \
	done

install-opencode-skills:
	@mkdir -p "$(OPENCODE_SKILLS_ROOT)"
	@set -- $(SKILL_NAMES); \
	for skill do \
		src="$(SKILLS_SRC_ROOT)/$$skill"; \
		dst="$(OPENCODE_SKILLS_ROOT)/$$skill"; \
		if [ -e "$$dst" ] && [ ! -L "$$dst" ]; then \
			echo "refusing to replace non-symlink install target: $$dst" >&2; \
			echo "move it aside manually if you want this repo to own that skill install" >&2; \
			exit 1; \
		fi; \
		ln -sfn "$$src" "$$dst"; \
	done
	@echo "linked $(words $(SKILL_NAMES)) skill modules to $(OPENCODE_SKILLS_ROOT)"

install-opencode-instructions:
	@mkdir -p "$$(dirname "$(OPENCODE_AGENTS)")"
	@if [ -e "$(OPENCODE_AGENTS)" ] && [ ! -L "$(OPENCODE_AGENTS)" ]; then \
		echo "refusing to replace non-symlink install target: $(OPENCODE_AGENTS)" >&2; \
		echo "move it aside manually if you want this repo to own that instruction file" >&2; \
		exit 1; \
	fi
	@ln -sfn "$(INSTRUCTIONS_SRC)" "$(OPENCODE_AGENTS)"
	@echo "linked OpenCode instructions to $(OPENCODE_AGENTS)"

install-hermes-instructions:
	@mkdir -p "$$(dirname "$(HERMES_SOUL)")"
	@if [ -e "$(HERMES_SOUL)" ] && [ ! -L "$(HERMES_SOUL)" ]; then \
		echo "refusing to replace non-symlink install target: $(HERMES_SOUL)" >&2; \
		echo "move it aside manually if you want this repo to own that instruction file" >&2; \
		exit 1; \
	fi
	@ln -sfn "$(INSTRUCTIONS_SRC)" "$(HERMES_SOUL)"
	@echo "linked Hermes default SOUL to $(HERMES_SOUL)"

install-opencode: install-opencode-skills install-opencode-instructions

install-hermes: install-hermes-instructions

install: install-opencode install-hermes
