import "./common.just"

dockerfile_packer := root + "/.ci/images/packer.Dockerfile"
dockerfile_template := templatesd + "/Dockerfile.packer.mustache"
lockfile := root + "/config/tools.lock.yaml"

[group('ci')]
ci-image target="packer":
    @docker build -t "ami-eks-{{target}}" -f "{{root}}/.ci/images/{{target}}.Dockerfile" .

[group('ci')]
ci-bump:
    #!/usr/bin/env bash
    set -euo pipefail
    mustache "{{lockfile}}" "{{dockerfile_template}}" > "{{dockerfile_packer}}"

[group('ci')]
get-latest-tag repo:
    gh api "repos/{{ repo }}/tags" \
        --method GET \
        -H "{{ accept_header }}" \
        -H "{{ github_api_ver_header }}" \
        --jq '.[0].name'

[group('ci')]
bump-pre-commit-version:
    #!/usr/bin/env bash
    set -euo pipefail
    config="{{ root }}/.pre-commit-config.yaml"

    # Print table header
    printf "%-45s %-15s %-15s %s\n" "REPO" "CURRENT" "LATEST" "STATUS"
    printf "%-45s %-15s %-15s %s\n" "----" "-------" "------" "------"

    count=$(yq '.repos | length' "$config")

    for ((i=0; i<count; i++)); do
        repo_url=$(yq ".repos[$i].repo" "$config")
        rev=$(yq ".repos[$i].rev" "$config")

        # Extract owner/repo from GitHub URL
        gh_repo=$(echo "$repo_url" | sed -E 's|https://github.com/||')

        # Skip repos pinned to "main" or other branch names
        if [[ "$rev" == "main" || ! "$rev" =~ ^v?[0-9] ]]; then
            printf "%-45s %-15s %-15s %s\n" "$gh_repo" "$rev" "-" "⏭️"
            continue
        fi

        # Get latest tag from GitHub API
        latest=$(just get-latest-tag "$gh_repo" 2>/dev/null || echo "")

        if [[ -z "$latest" ]]; then
            printf "%-45s %-15s %-15s %s\n" "$gh_repo" "$rev" "?" "🆘"
            continue
        fi

        if [[ "$rev" != "$latest" ]]; then
            yq -i "(.repos[] | select(.repo == \"$repo_url\")).rev = \"$latest\"" "$config"
            printf "%-45s %-15s %-15s %s\n" "$gh_repo" "$rev" "$latest" "🚀"
        else
            printf "%-45s %-15s %-15s %s\n" "$gh_repo" "$rev" "$latest" "😎"
        fi
    done
# [group('ci')]
# [linux]
# ci-build:

# [group('ci')]
# [linux]
# ci-init:
