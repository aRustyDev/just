root := `git rev-parse --show-toplevel`

zed_global := root + "/ai/.templates/zed.global.settings.json.mustache"
zed_project := root + "/ai/.templates/zed.project.settings.json.mustache"

just-mcp:
    #!/usr/bin/env bash
    git clone https://github.com/toolprint/just-mcp
    cargo install --path just-mcp --features "vector-search,local-embeddings"

zed:
    #!/usr/bin/env bash
    global="$(mustache "docker.mcp.yaml" "{{zed_global}}")"
    global="$(echo "$global" | envsubst)"
    global="$(echo "$global" | op inject)"
    echo $global > "zed.global.settings.json"
    project="$(mustache "docker.mcp.yaml" "{{zed_project}}")"
    project="$(echo "$project" | envsubst)"
    project="$(echo "$project" | op inject)"
    echo $project > "zed.project.settings.json"

docker-servers:
    docker run -d --name zed-server -p 8080:8080 mcp/zed-server
    docker run -d --name zed-server -p 8080:8080 mcp/zed-server
    docker run -d --name zed-server -p 8080:8080 mcp/zed-server
    docker run -d --name zed-server -p 8080:8080 mcp/zed-server
