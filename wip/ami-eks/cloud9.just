import './common.just'

# Variables

one_month_ago := `date -v -1m +%Y-%m-%d`
eks_latest := "1.33"

# Env Vars
# : These are for sourcing values that are required but likely already in the ENV.
# : These can be overridden by supplying them to the dot-env file (see top of file 'set dotenv-path' )

region := env("AWS_DEFAULT_REGION")
source := env("SOURCE", "aws")
distro := env("DISTRO", "AmazonLinux")
arch := env("ARCH", "amd64")

# Generate report of image's SBOM file evaluation.
[group('cloud9')]
[group('security')]
trivy-cve sbomUrl pkgTypes ignoreBad:
    #!/usr/bin/env bash
    just get "/api/distinct-os/{{ sbomUrl }}/{{ pkgTypes }}/{{ ignoreBad }}"

# Get SignedUrl for Cloud9 S3 bucket file. Valid for 5 minutes.
[group('cloud9')]
[group('s3')]
s3-signed-url bucketname filename:
    #!/usr/bin/env bash
    just get "/api/s3-signed-url/{{ bucketname }}/{{ filename }}"

# Fetch file data from S3 w/ appropriate content type.
[group('cloud9')]
[group('s3')]
ls-file-data bucketname filename:
    #!/usr/bin/env bash
    just get "/api/file-data/{{ bucketname }}/{{ filename }}"

# List distinct OS values for the provided source.
[group('cloud9')]
[group('list')]
ls-distros source=source:
    #!/usr/bin/env bash
    just get "/api/distinct-os/{{ source }}"

# List distinct architecture values for the provided source.
[group('cloud9')]
[group('list')]
ls-arch source=source:
    #!/usr/bin/env bash
    just get "/api/distinct-architecture/{{ source }}"

# List distinct feature values for the provided source.
[group('cloud9')]
[group('list')]
ls-features source=source:
    #!/usr/bin/env bash
    just get "/api/distinct-features/{{ source }}"

# List all versions for the given category and field name.
[group('cloud9')]
[group('list')]
ls-versions source=source:
    #!/usr/bin/env bash
    just get "/api/distinct-versions/{{ source }}"

# List all images available for the provided source.
[group('cloud9')]
[group('list')]
ls-images source=source:
    #!/usr/bin/env bash
    just get "/api/images/{{ source }}?date_created=gte{{ one_month_ago }}"

# Get image information.
[group('cloud9')]
[group('get')]
describe ami arch=arch:
    #!/usr/bin/env bash
    just get "/api/image-info/{{ ami }}/{{ arch }}"

# List unique, non-expired Cloud 9 releases for given 'source'.
[group('cloud9')]
[group('list')]
ls-uniq-releases source=source:
    #!/usr/bin/env bash
    just get "/api/unique-releases/{{ source }}"

# Check if a Cloud9 AMI ID is expired.
[group('cloud9')]
[group('get')]
check cecid region=region:
    #!/usr/bin/env bash
    just get "/api/expiration-status/ami/{{ region }}/{{ cecid }}"

# List all Cloud9 supported EKS Images @ version
[group('cloud9')]
[group('list')]
ls-uniq-eks version=eks_latest:
    #!/usr/bin/env bash
    just ls-images | "{{ jq }}" --arg v "{{ version }}" -f "{{ jqd }}/latest.eks.amd.jq"

# Get the latest AMI ID for given distro, region, and arch
[group('cloud9')]
[group('get')]
latest-ami d=distro r=region a=arch:
    #!/usr/bin/env bash
    # filter returned json by arch, region, and distro to find latest-ami;
    just ls-images | "{{ jq }}" -r --arg arch "{{ a }}" --arg region "{{ r }}" --arg distro "{{ d }}" -f {{ jqd }}/get-ami-latest.jq

# Update Config.yaml with latest AMI info for given distro
[group('cloud9')]
hydrate-cloud9 distro=distro:
    #!/usr/bin/env bash
    echo "[ hydrate: cloud9 ]"
    ami=$(just latest-ami "{{ distro }}")
    "{{ yq }}" -i 'del(.ec2.ami.distro)' "{{ config }}"
    just update-config ".ec2.ami.id" $ami
    just update-config ".ec2.ami.name" $(just describe "$ami" | "{{ jq }}" -r '.ami_name')
