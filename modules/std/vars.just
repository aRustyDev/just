set shell := ["/usr/bin/env", "bash", "-c"]

# Directories (Computed)

root := `git rev-parse --show-toplevel`

# Directories (Defined)

templatesd := root + "/.templates"
scriptsd := root + "/scripts"
configsd := root + "/config"
pythond := scriptsd + "/python"
justd := scriptsd + "/just"
bashd := scriptsd + "/bash"
datad := root + "/data"
varsd := datad + "/vars"
awkd := scriptsd + "/awk"
jqd := scriptsd + "/jq"

# Prefixes

varfiles := varsd / environment

# UI Helper

br := "\n-----------------------------------\n"

## Config

config := root / "config.yaml"
config_default_tmpl := templatesd / "config.default.mustache"
config_empty_tmpl := templatesd / "config.empty.mustache"

# Dependencies
# : These are used to verify the tool is in the PATH, will cause 'just' to fail if not
# : Call these like '{{ tool_name }}' in recipes
# : Will resolve to the absolute path of the tool if found in PATH

pyenv_root := env("PYENV_ROOT", env("HOME") + "/.pyenv")
mustache := require("mustache")
aws_sso := require("aws-sso")
python3 := require("python3")
python := pyenv_root + "/shims/python3"
packer := require("packer")
sponge := require("sponge")
pyenv := require("pyenv")
aws := require("aws")
awk := require("awk")
jq := require("jq")
yq := require("yq")
go := require("go")

# Env Vars
# : These are for sourcing values that are required but likely already in the ENV.
# : These can be overridden by supplying them to the dot-env file (see top of file 'set dotenv-path' )

token := if which("op") != "" { shell("op read " + env("CLOUD9_TOKEN") + " 2>/dev/null") } else { env("CLOUD9_TOKEN") }
environment := env("ENVIRONMENT", "dev")
debug := if env("DEBUG", "") != "" { "true" } else { "false" }

# === === === === === === === === === === === === === === === === === === === === === === ===
#  Recipes
# === === === === === === === === === === === === === === === === === === === === === === ===

# Update a key/value in the config file
[group('core')]
[private]
update-config key val:
    #!/usr/bin/env bash
    echo "[ :: {{ key }} ]"
    v="{{ val }}" "{{ yq }}" -i '{{ key }} = env(v)' "{{ config }}"
    # If this recipe was called from within another recipe (ie its automated)
    if [ "{{ is_dependency() }}" = "true" ]; then
        v="{{ key }}" "{{ yq }}" -i '.metadata.automated += "env(v)"' "{{ config }}"
    fi

# Hydrate varfile templates using config.yaml
[group('template')]
hydrate-vars tgt:
    #!/usr/bin/env bash
    echo "[ hydrate: {{ tgt }} ]"
    "{{ mustache }}" "{{ config }}" "{{ templatesd }}/{{ tgt }}.mustache" > "{{ varfiles }}.{{ tgt }}.hcl"

# Hydrate Config.yaml file with standard tags
[group('template')]
config-tags: config-tags-git
    #!/usr/bin/env bash
    echo "[ config(tags) ]"
    just update-config ".tags.environment" "{{ environment }}"
    just update-config ".tags.Name" "ami-pipeline-{{ environment }}"

# Hydrate Config.yaml file with git related tags
[group('template')]
config-tags-git:
    #!/usr/bin/env bash
    echo "[ config(tags:git) ]"
    just update-config ".tags.owner.name" $(git config user.name)
    just update-config ".tags.owner.email" $(git config user.email)

# Hydrate Config.yaml file with relevant files/dirs
[group('template')]
config-paths:
    #!/usr/bin/env bash
    echo "[ config(dirs) ]"
    just update-config ".dirs.templates" "{{ templatesd }}"
    just update-config ".dirs.scripts" "{{ scriptsd }}"
    just update-config ".dirs.configs" "{{ configsd }}"
    just update-config ".dirs.bash" "{{ bashd }}"
    just update-config ".dirs.data" "{{ datad }}"
    just update-config ".dirs.vars" "{{ varsd }}"
    just update-config ".dirs.just" "{{ justd }}"
    just update-config ".dirs.root" "{{ root }}"
    just update-config ".dirs.pwd" $PWD
    just update-config ".dirs.py" "{{ pythond }}"
    just update-config ".dirs.jq" "{{ jqd }}"

# Convert a YAML file to JSON
[group('core')]
[private]
as_json target:
    @yq --output-format json '.' {{ root }}/{{ target }}
