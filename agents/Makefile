SKILLS_SRC_ROOT := $(CURDIR)/skills
SKILL_MANIFESTS := $(wildcard $(SKILLS_SRC_ROOT)/*/SKILL.md)
SKILL_DIRS := $(patsubst %/SKILL.md,%,$(SKILL_MANIFESTS))
SKILL_NAMES := $(sort $(notdir $(SKILL_DIRS)))

ifeq ($(OS),Windows_NT)
WIN_HOME := $(subst \,/,$(USERPROFILE))
CODEX_SKILLS_ROOT := $(WIN_HOME)/.codex/skills
AGENTS_SKILLS_ROOT := $(WIN_HOME)/.agents/skills/my-skill

define win_install_skills_script
$$ErrorActionPreference = 'Stop';
$$root = '$(1)';
$$sourceRoot = '$(SKILLS_SRC_ROOT)';
New-Item -ItemType Directory -Force -Path $$root | Out-Null;
$$skills = '$(SKILL_NAMES)' -split ' ';
foreach ($$skill in $$skills) {
	$$source = Join-Path $$sourceRoot $$skill;
	$$target = Join-Path $$root $$skill;
	$$sourceSkill = Join-Path $$source 'SKILL.md';
	$$targetSkill = Join-Path $$target 'SKILL.md';
	if (Test-Path -LiteralPath $$target) {
		$$item = Get-Item -LiteralPath $$target;
		if ($$item.LinkType -in @('Junction', 'SymbolicLink')) {
			[IO.Directory]::Delete($$target);
		} elseif ((Test-Path -LiteralPath $$targetSkill -PathType Leaf) -and (Test-Path -LiteralPath $$sourceSkill -PathType Leaf)) {
			fc.exe /B $$sourceSkill $$targetSkill | Out-Null;
			if ($$LASTEXITCODE -eq 0) {
				Remove-Item -LiteralPath $$target -Recurse -Force;
			} else {
				[Console]::Error.WriteLine('refusing to replace non-symlink install target: ' + $$target);
				[Console]::Error.WriteLine('move it aside manually if you want this repo to own that skill install');
				exit 1;
			}
		} else {
			[Console]::Error.WriteLine('refusing to replace non-symlink install target: ' + $$target);
			[Console]::Error.WriteLine('move it aside manually if you want this repo to own that skill install');
			exit 1;
		}
	}
	New-Item -ItemType Junction -Path $$target -Target $$source | Out-Null;
}
endef

define install_skills
@powershell -NoProfile -Command "$(strip $(call win_install_skills_script,$(1)))"
@echo "linked $(words $(SKILL_NAMES)) skill modules to $(1)"
endef

define show_skills
@powershell -NoProfile -Command "'$(SKILL_NAMES)' -split ' ' | ForEach-Object { Write-Output $$_ }"
endef

else
CODEX_SKILLS_ROOT := $(HOME)/.codex/skills
AGENTS_SKILLS_ROOT := $(HOME)/.agents/skills/my-skill

define install_skills
@mkdir -p "$(1)"
@set -- $(SKILL_NAMES); \
for skill do \
	src="$(SKILLS_SRC_ROOT)/$$skill"; \
	dst="$(1)/$$skill"; \
	if [ -e "$$dst" ] && [ ! -L "$$dst" ]; then \
		if [ -f "$$dst/SKILL.md" ] && [ -f "$$src/SKILL.md" ] && cmp -s "$$src/SKILL.md" "$$dst/SKILL.md"; then \
			rm -rf "$$dst"; \
		else \
			echo "refusing to replace non-symlink install target: $$dst" >&2; \
			echo "move it aside manually if you want this repo to own that skill install" >&2; \
			exit 1; \
		fi; \
	fi; \
	ln -sfn "$$src" "$$dst"; \
done
@echo "linked $(words $(SKILL_NAMES)) skill modules to $(1)"
endef

define show_skills
@set -- $(SKILL_NAMES); \
for skill do \
	echo "$$skill"; \
done
endef

endif

.PHONY: install-codex install-agents list-skills

list-skills:
	$(call show_skills)

install-codex:
	$(call install_skills,$(CODEX_SKILLS_ROOT))

install-agents:
	$(call install_skills,$(AGENTS_SKILLS_ROOT))
