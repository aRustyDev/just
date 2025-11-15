import '../.build/just/lib.just'

ssh := root + "/ssh"
output_file := ssh + "/config"
dotssh := if env("XDG_CONFIG_HOME", "") != "" { "$XDG_CONFIG_HOME/ssh" } else { "$HOME/.ssh" }

list-targets target="*":
    @ls -1 {{ if target == "*" { ssh + "/configs/" } else { ssh + "/configs/" + target } }}

[doc('Hydrate env vars in ssh config templates')]
build +targets=profile:
    @echo "[SSH Config] | Building"
    @for cfg in {{targets}}; do \
        just template {{ if cfg == "cfs" { "engagement" } else { "" } }}; \
    done
    @for cfg in `lsd -U {{ ssh + "/configs/{includes/orb," + replace(targets, " ", "/*,") + "/*" + ",default}" }}`; do \
        DOTSSH={{ dotssh }} \
        envsubst < "$cfg"; \
        echo ""; \
    done > {{ output_file }}

[doc('Build, op inject, and install ssh configs')]
install +targets=profile:
    @echo "[SSH Config] | Installing"
    @just build {{ targets }}
    @op inject -f -i {{ output_file }} -o {{ dotssh }}/config
    @chmod 600 {{ dotssh }}/config
    @just clean
    @echo "[SSH Config] | [x] Done"

clean:
    @rm -f {{ output_file }}

template target="":
    #!/usr/bin/env bash
    if [ {{target}} == "" ]; then exit 0; fi
    outpath={{ if target =~ "cfs" { "cfs/engagement" } else { "todo" } }}
    op item list --tags ssh --format json | jq -c '[ .[] | select(.tags | contains(["{{target}}"])) ] | sort_by(.vault.id)[]' | while read -r item; do
        name=$(echo "${item}" | jq -r '.vault.name | ascii_downcase')
        vault=$(echo "${item}" | jq -r '.vault.id')
        uuid=$(echo "${item}" | jq -r '.id')
        echo "{shortname: ${name}, vault: ${vault}, uuid: ${uuid}}" | mustache templates/{{outpath}}-config.mustache > {{ssh}}/configs/{{outpath}}-${name}
    done

test:
    #!/usr/bin/env bash
    op item list --tags ssh --format json | jq -c '[ .[] | select(.tags | contains(["engagement"])) ] | sort_by(.vault.id)[]' | while read -r item; do
        name=$(echo "${item}" | jq -r '.vault.name | ascii_downcase')
        vault=$(echo "${item}" | jq -r '.vault.id')
        uuid=$(echo "${item}" | jq -r '.id')
        echo "{shortname: ${name}, vault: ${vault}, uuid: ${uuid}}" | mustache templates/engagement-config.mustache
    done

rotate:
    @echo "Update Key in 1password"
    @echo "Update key in GitLab (govus.cisco.com: Sign + Auth)"
    @echo "Update key in GitHub (govus.cisco.com: Auth)"
    @echo "Update key in GitHub (govus.cisco.com: Sign)"
    @echo "Update key in GitLab (cisco.com: Sign + Auth)"
    @echo "Update key in GitHub (cisco.com: Auth)"
    @echo "Update key in GitHub (cisco.com: Sign)"
    @echo "Trigger update of authorized_keys (Locally)"
    @echo "Create MR to trigger redeploy for bastion"
    @echo "Trigger update of authorized_keys (Bastion)"

op-update:
    @ssh-keyscan eng-bastion-1.devops.map.cisco | grep ssh-ed25519
