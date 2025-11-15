import "./common.just"

export GIT_ROOT := root
compose := root + "/docker-compose.yaml"
traefik := root + "/docker-compose.traefik.yaml"
compose_tmpl := templatesd + "/docker-compose.mustache"
traefik_tmpl := templatesd + "/docker-compose.traefik.mustache"
zed_tmpl := templatesd + "/zed.settings.mustache"
zed_config := root + "/.zed/settings.local.json"
repo_name := shell("basename " + root)
json := "{path: '" + root + "', name: '" + repo_name + "'}"
traefik_json := `docker container ls --filter NAME=traefik --format json`
default_subject := "/C=US/ST=Dev/L=Local/O=" + uppercase(repo_name) + "/OU=CA/CN"

mcp-init: mcp-certs hydrate-mcp
    #!/usr/bin/env bash
    mkdir -p ~/.postgresql
    chmod 700 ~/.postgresql
    cp "{{root}}/data/certs/ca/ca.pem" ~/.postgresql/root.crt
    chmod 600 ~/.postgresql/root.crt
    if [[ "{{traefik_json}}" == "" ]]; then
        docker compose -f "{{traefik}}" up -d
    fi
    docker compose -f "{{compose}}" up -d

hydrate-mcp:
    echo "{{json}}" | mustache "{{zed_tmpl}}" | envsubst | op --account "cisco.1password.com" inject > "{{zed_config}}"
    echo "{{json}}" | mustache "{{compose_tmpl}}" | envsubst | op --account "cisco.1password.com" inject > "{{compose}}"
    echo "{{json}}" | mustache "{{traefik_tmpl}}" | envsubst | op --account "cisco.1password.com" inject > "{{traefik}}"
    @echo "TODO: Cursor"
    @echo "TODO: Claude Desktop"
    @echo "TODO: Claude Code"
    @echo "TODO: OpenCode"

mcp-certs: clean-mcp (certgen "mongo") (certgen "postgres")
    #!/usr/bin/env bash
    if [ ! -f ~/.postgresql/root.crt ]; then
        mkdir -p ~/.postgresql
        chmod 700 ~/.postgresql
        just certgen "ca"
        openssl req -x509 -new -nodes -key "{{root}}/data/certs/ca/ca.key" -sha256 -days 365 -subj "{{default_subject}}=ca.{{lowercase(repo_name)}}.localhost" -out "{{root}}/data/certs/ca/ca.pem"
        cp "{{root}}/data/certs/ca/ca.pem" ~/.postgresql/root.crt
        cp "{{root}}/data/certs/ca/ca.key" ~/.postgresql/root.key
        chmod 600 ~/.postgresql/root.{crt,key}
        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "{{root}}/data/certs/ca/ca.pem"
    else
        cp ~/.postgresql/root.key "{{root}}/data/certs/ca/ca.key"
        cp ~/.postgresql/root.crt "{{root}}/data/certs/ca/ca.pem"
    fi
    just certreq "mongo"
    just certreq "postgres"
    sudo sed -i'' -e '1i\
    # Docker Endpoints for {{repo_name}}' /etc/hosts
    # replace(join()): creates space separated list of hostnames
    sudo sed -i'' -e '2i\
    127.0.0.1 {{replace(join("mongo", "pg"), "/", "." + repo_name + ".localhost ")}}' /etc/hosts

certgen target:
    openssl genrsa -out "{{root}}/data/certs/{{target}}/{{if target == "ca" { "ca" } else { "server" } }}.key" 4096

certreq target:
    #!/usr/bin/env bash
    subject="{{default_subject}}={{lowercase(target)}}.{{lowercase(repo_name)}}.localhost"
    openssl req -new -key "{{root}}/data/certs/{{target}}/server.key" -subj "$subject" -out "{{root}}/data/certs/{{target}}/server.csr"
    openssl x509 -req -in "{{root}}/data/certs/{{target}}/server.csr" -CA "{{root}}/data/certs/ca/ca.pem" -CAkey "{{root}}/data/certs/ca/ca.key" -CAcreateserial -out "{{root}}/data/certs/{{target}}/server.crt" -days 365 -sha256
    cat "{{root}}/data/certs/{{target}}/server.crt" "{{root}}/data/certs/{{target}}/server.key" > "{{root}}/data/certs/{{target}}/server.pem"
    chmod 600 "{{root}}/data/certs/{{target}}/server.key" "{{root}}/data/certs/{{target}}/server.pem"

clean-mcp:
    rm -f "{{compose}}" "{{traefik}}" "{{zed_config}}"
    rm -f "{{root}}/data/certs/{ca,mongo,postgres}/server.*"
    sudo sed -i'' -e '/{{repo_name}}/d' /etc/hosts
    rm -f ~/.postgresql/root.crt

# postgres://postgres:CHANGE_ME_SECURE@pg.ami-eks.localhost/ami-eks?sslmode=verify-full
# mongodb://mongo.ami-eks.localhost/?authSource=admin
mcp-test:
    #!/usr/bin/env bash
    op run -- mongosh --tls \
      --tlsCAFile "{{root}}/data/certs/ca/ca.pem" \
      --username mongo \
      --password op://Employee/mcp/mongo/pass \
      "mongodb://mongo.{{repo_name}}.localhost/?authSource=admin"
    user=$(op read "op://Employee/mcp/postgres/user")
    cred=$(op read "op://Employee/mcp/postgres/pass")
    psql "postgres://$user:$cred@pg.{{repo_name}}.localhost/{{repo_name}}?sslmode=verify-full"
