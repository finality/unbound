# unbound

This image builds Unbound from upstream NLnet Labs source on top of Red Hat UBI Minimal and publishes it to GitHub Container Registry.

The directory is structured to become its own standalone public repository.

## Source of truth

- Base image: `registry.access.redhat.com/ubi9/ubi-minimal:latest`
- Upstream source: `https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz`
- Integrity check: `UNBOUND_SHA256` in `version.env`

## Runtime behavior

- Listens on `0.0.0.0:${UNBOUND_PORT}` and defaults to port `5053`
- Reads mounted config fragments from `/config/*.conf`
- Ships no hard-coded upstreams; use mounted fragments such as:
  - `examples/forward-records.conf`
  - `examples/local-access.conf`
- Fails the image build if the final stage cannot execute `unbound`
- Runs a startup self-check in the entrypoint before serving DNS

## Publishing

The workflow at `.github/workflows/publish-unbound.yml` publishes:

- `ghcr.io/<owner>/<repo>:latest`
- `ghcr.io/<owner>/<repo>:${UNBOUND_VERSION}`
- `ghcr.io/<owner>/<repo>:sha-<gitsha>`

The image name is derived automatically from the GitHub repository path:

- workflow value: `ghcr.io/${{ github.repository }}`
- if the repository is named `unbound`, the published image will be `ghcr.io/<owner>/unbound`

## Updating Unbound

1. Update `UNBOUND_VERSION` and `UNBOUND_SHA256` in `version.env`.
2. Push the change or run the workflow manually.
3. After GHCR publishes the image, pin VyOS to the image digest rather than a mutable tag.
