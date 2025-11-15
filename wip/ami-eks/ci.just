import "./common.just"

dockerfile_packer := root + "/.ci/images/packer.Dockerfile"
dockerfile_template := templatesd + "/Dockerfile.packer.mustache"
lockfile := root + "/config/tools.lock.yaml"

[group('ci')]
ci-image target="packer":
    @docker build -t "ami-eks-{{target}}" -f "{{root}}/.ci/images/{{target}}.Dockerfile" .

ci-bump:
    #!/usr/bin/env bash
    set -euo pipefail
    mustache "{{lockfile}}" "{{dockerfile_template}}" > "{{dockerfile_packer}}"

# [group('ci')]
# [linux]
# ci-build:

# [group('ci')]
# [linux]
# ci-init:
