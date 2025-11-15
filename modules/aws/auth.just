# Ensure AWS tokens are refreshed
[group('core')]
[private]
authn_aws:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "[ authn(aws) ]"
    if "{{ aws }}" sts get-caller-identity >/dev/null 2>&1; then
        expires=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$("{{ aws }}" configure get x_security_token_expires)" +%s 2>/dev/null)
        now=$(date +%s)
        diff=$(($expires - $now))
        # Refresh if less than 15 minutes left
        if [ "$diff" -lt 900 ]; then
            echo "AWS credentials expiring soon ($diff s); refreshing SSO..."
            "{{ aws_sso }}" -config "{{ aws_sso_gov }}"
        fi
    else
        echo "AWS identity unavailable; invoking SSO login..."
        "{{ aws_sso }}" -config "{{ aws_sso_gov }}"
    fi
