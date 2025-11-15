cspell action="check":
    #!/usr/bin/env bash
    echo "[ cspell ]"
    words=$(npx -y cspell $(git ls-files) --no-exit-code --unique --config "{{ root }}/.cspell.json" --no-progress --no-summary --gitignore --words-only)
    words=($words)
    json=$(printf '%s\n' "${words[@]}" | jq -R . | jq -s .)
    if [ "{{ action }}" == "fix" ]; then
        jq --argjson json "$json" '.words = ((.words + $json) | sort | unique) ' "{{ root }}/.cspell.json" {{ if action == "fix" { "| sponge " + root + "/.cspell.json" } else { "" } }}
    else
        if [ ${#words[@]} -gt 0 ]; then
            echo "Run: 'just cspell fix' to add these words to .cspell.json"
            echo "$json"
        fi
    fi
