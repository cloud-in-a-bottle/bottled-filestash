image     := "localhost/filestash-test"
container := "filestash-test"
data_dir  := justfile_directory() / "test-data"
platform  := if arch() == "aarch64" { "linux/arm64" } else { "linux/amd64" }

# Build and run a clean instance locally (http://localhost:8334)
test: build _stop
    rm -rf {{data_dir}}
    mkdir -p {{data_dir}}
    just _run

# Build and run, preserving existing data across restarts
run: build _stop
    mkdir -p {{data_dir}}
    just _run

# Build the image
build:
    podman build --platform {{platform}} -t {{image}} .

# Stop and remove any running test container
_stop:
    -podman rm -f {{container}}

_run:
    podman run \
        --name {{container}} \
        --rm \
        -p 8334:8334 \
        -v {{data_dir}}:/data \
        -e OPENHOST_APP_NAME=filestash \
        -e OPENHOST_ZONE_DOMAIN=localhost \
        -e OPENHOST_APP_DATA_DIR=/data/app_data/filestash \
        -e EXTERNAL_HOST=localhost:8334 \
        {{image}}
