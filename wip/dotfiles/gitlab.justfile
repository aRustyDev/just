import "../justfile"

mktree:
    mkdir -p {{XDG_DATA_HOME}}/map

# Clone the set of repos related to 'target' : [terraform, utilities, docs, infrastructure]
clone target: mktree
    #!/usr/bin/env bash
    selector={{ if target == "terraform" { "terraform-map-" } else { "does-not-exist: " + target } }}
    cd {{XDG_DATA_HOME}}/map
    glab repo list --group c4p/map -G -a -F json | jq -r --arg prefix "$selector" '.[] | .name | select(. | contains($prefix)) | "git {{ if present == "true" { "clone --reference " + pwd + "\(.)" } else { "clone " } }}git@sscm.gus.cisco.com:c4p/map/\(.).git"'
