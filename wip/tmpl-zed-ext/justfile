root := `git rev-parse --show-toplevel`
tmpls := root + "/.zed/templates"
extn_tmpl := tmpls + "extension.mustache"

init kind name: init-pre-commit
    #!/usr/bin/env bash
    echo "foo"
    export id=$(echo "{{ name }}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_')
    export name=$(echo "{{ name }}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_')
    just "init-{{ kind }}" "${name}"
    sed -i '' 's/tmpl-zed-extension/{{ name }}/g' "{{ root }}/Cargo.toml"
    sed -i '' 's/tmpl-zed-extension/{{ name }}/g' "{{ root }}/README.md"

init-pre-commit:
    pip install pre-commit
    pre-commit install --install-hooks

init-languages name:
    #!/usr/bin/env bash
    echo "bar"
    json1='{"name":"{{ name }}","id":"{{ env("id") }}","owner":"{{ env("owner") }}","author":"{{ env("author") }}","email":"{{ env("id") }}","lang-servers":[{"name":"{{ name }}","id":"{{ env("id") }}",}],}'
    json2='{"name":"{{ name }}","id":"{{ env("id") }}",}'
    mkdir -p "{{ root }}/grammars"
    mkdir -p "{{ root }}/languages/{{ name }}"
    touch "{{ root }}/languages/{{ name }}/config.toml"
    touch "{{ root }}/languages/{{ name }}/highlights.scm"
    touch "{{ root }}/languages/{{ name }}/runnables.scm"
    touch "{{ root }}/languages/{{ name }}/redactions.scm"
    touch "{{ root }}/languages/{{ name }}/textobjects.scm"
    touch "{{ root }}/languages/{{ name }}/overrides.scm"
    touch "{{ root }}/languages/{{ name }}/injections.scm"
    touch "{{ root }}/languages/{{ name }}/indents.scm"
    touch "{{ root }}/languages/{{ name }}/outline.scm"
    touch "{{ root }}/languages/{{ name }}/brackets.scm"
    echo $json | mustache "{{ extn_tmpl }}" > "{{ root }}/extension.toml"


init-mcp name:
    #!/usr/bin/env bash
    json='{"lang-servers":[{"name":"{{ name }}","id":"{{ env("id") }}",}],}'
    echo "mcp server"
    echo $json | mustache "{{ extn_tmpl }}" > "{{ root }}/extension.toml"

init-debuggers name:
    echo "TODO: debuggers"
    json1='{"debug-adapters":[{"name":"{{ name }}","id":"{{ env("id") }}",}],}'
    json2='{"debug-locators":[{"name":"{{ name }}","id":"{{ env("id") }}",}],}'
    mkdir -p "{{ root }}/debug_adapter_schemas/{{ name }}.json"

init-themes name:
    echo "TODO: themes"
    json='{"lang-servers":[{"name":"{{ name }}","id":"{{ env("id") }}",}],}'
    mkdir -p "{{ root }}/themes"
    touch "{{ root }}/themes/{{ name }}.json"

init-icons name:
    echo "TODO: icon theme"

init-slash name:
    echo "TODO: slash commands"
    json='{"lang-servers":[{"name":"{{ name }}","id":"{{ env("id") }}",}],}'

bump:
    echo "TODO: bump all versions"
    json='{"lang-servers":[{"name":"{{ name }}","id":"{{ env("id") }}",}],}'
