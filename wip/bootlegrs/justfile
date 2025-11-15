root := `git rev-parse --show-toplevel`
schemas := "rotgut recipe speakeasy still"

check:
    cargo check

build:
    cargo build

commit:
    cd docs && mdbook build
    cargo doc
    # pre-commit --rusn
    lazygit

gen-schemas: build
    @for scheme in {{schemas}}; do ./target/debug/bootleg schema --schema $scheme | jq '.' > data/schemas/$scheme.json; done
