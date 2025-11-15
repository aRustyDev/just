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
