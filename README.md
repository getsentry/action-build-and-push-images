# action-build-and-push-images

A composite GitHub Action that builds container images with Docker Buildx and publishes them to:

- GitHub Container Registry (GHCR)
- Google Artifact Registry (GAR)

The action always builds. It publishes only for the events listed in [Publishing behavior](#publishing-behavior).

## Usage

### Required permissions

To publish, add this permissions block to your workflow:

```yaml
permissions:
  contents: read
  packages: write      # Required for GHCR
  id-token: write      # Required for Google Artifact Registry (GAR)
```

If you only build, set `packages` to `read` and omit `id-token`:

```yaml
permissions:
  contents: read
  packages: read      # Required to read from GHCR if using as cache
```

See the [GitHub Actions permissions docs](https://docs.github.com/en/actions/using-jobs/assigning-permissions-to-jobs) for details.

### Basic usage

```yaml
- name: Build and push image
  uses: getsentry/action-build-and-push-images@sha
  with:
    image_name: 'sentry'
    platforms: 'linux/amd64'
```

### Multi-architecture with a matrix strategy

Each matrix job pushes its own image. The action does not merge them into a multi-arch manifest. Give each job a distinct `tag_suffix` so the jobs do not overwrite each other's tags, and a distinct cache scope so they do not overwrite each other's cache. Disable `tag_latest` and `tag_nightly`, because those tags have no suffix. Assemble the manifest in a later job, for example with `docker buildx imagetools create`.

```yaml
jobs:
  build:
    strategy:
      matrix:
        include:
          - arch: amd64
            runner: ubuntu-24.04
          - arch: arm64
            runner: ubuntu-24.04-arm
    runs-on: ${{ matrix.runner }}
    steps:
      - name: Build and push image
        uses: getsentry/action-build-and-push-images@sha
        with:
          image_name: 'sentry'
          platforms: linux/${{ matrix.arch }}
          tag_suffix: -${{ matrix.arch }}
          tag_latest: false
          tag_nightly: false
          cache_from: type=gha,scope=buildcache-${{ matrix.arch }}
          cache_to: type=gha,mode=max,scope=buildcache-${{ matrix.arch }}
```

When every platform in `platforms` matches the runner's architecture, the action skips QEMU setup.

### Custom build configuration

```yaml
- name: Build and push image
  uses: getsentry/action-build-and-push-images@sha
  with:
    image_name: 'sentry'
    platforms: 'linux/amd64'
    dockerfile_path: './docker/Dockerfile'
    build_context: './src'
    build_target: 'production'
    build_args: |
      ENVIRONMENT=production
      DEBUG=false
```

### Publishing to Google Artifact Registry

The action authenticates to GAR with Workload Identity Federation. It derives the registry host from the first path segment of `google_ar_image_name`.

```yaml
- name: Build and push image
  uses: getsentry/action-build-and-push-images@sha
  with:
    image_name: 'sentry'
    platforms: 'linux/amd64'

    # Enable GAR publishing
    google_ar: 'true'
    google_ar_image_name: 'us-central1-docker.pkg.dev/myproject/myrepo/myapp'

    # Authentication (required for GAR)
    google_workload_identity_provider: 'projects/123/locations/global/workloadIdentityPools/pool/providers/provider'
    google_service_account: 'service-account@project.iam.gserviceaccount.com'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `image_name` | Base image name | Yes | - |
| `dockerfile_path` | Path to Dockerfile | No | `./Dockerfile` |
| `build_context` | Build context directory | No | `.` |
| `build_target` | Docker build target stage | No | - |
| `build_args` | Docker build arguments (multiline) | No | - |
| `release_branches` | Comma-separated release branch prefixes. A push to `<prefix>/*` publishes. | No | `release,releases` |
| `ghcr` | Enable GitHub Container Registry | No | `true` |
| `ghcr_image_name` | GHCR image name | No | `ghcr.io/{owner}/{image_name}` |
| `publish_on_pr` | Publish images on pull requests (SHA tags only) | No | `false` |
| `google_ar` | Enable Google Artifact Registry | No | `false` |
| `google_ar_image_name` | GAR image name. Required when `google_ar` is `true`. | No | - |
| `tags` | Additional tags, passed unchanged to `docker/build-push-action`. Use full image references. | No | - |
| `tag_prefix` | Prefix for the SHA tag | No | - |
| `tag_suffix` | Suffix for the SHA tag | No | - |
| `tag_latest` | Add the `latest` tag on default-branch builds | No | `true` |
| `tag_nightly` | Add the `nightly` tag on default-branch builds (GHCR only) | No | `true` |
| `google_workload_identity_provider` | Google Workload Identity Provider | No | - |
| `google_service_account` | Google Service Account | No | - |
| `platforms` | Platforms to build (for example `linux/amd64,linux/arm64`) | No | `linux/amd64` |
| `outputs` | Extra BuildKit output destinations (for example `type=docker`) | No | - |
| `cache_from` | BuildKit cache source (empty to disable) | No | `type=gha,scope=buildcache` |
| `cache_to` | BuildKit cache destination, only used when publishing (empty to disable) | No | `type=gha,mode=max,scope=buildcache` |

## Outputs

| Output | Description |
|--------|-------------|
| `ghcr_image_url` | Full GHCR image URL with the SHA tag. Empty when the action does not publish to GHCR. |
| `gar_image_url` | Full GAR image URL with the SHA tag. Empty when the action does not publish to GAR. |

### Using outputs

```yaml
- name: Build and push image
  id: build
  uses: getsentry/action-build-and-push-images@sha
  with:
    image_name: 'sentry'
    platforms: 'linux/amd64'

- name: Use outputs
  run: |
    echo "GHCR URL: ${{ steps.build.outputs.ghcr_image_url }}"
```

## Publishing behavior

The action publishes to an enabled registry (`ghcr` or `google_ar`) on these events. GHCR and GAR follow the same rules.

| Event | Publishes | Tags |
|-------|-----------|------|
| Push to the default branch | Yes | SHA, `latest`, `nightly` (GHCR only) |
| Merge queue (`merge_group`) targeting the default branch | Yes | SHA, `latest`, `nightly` (GHCR only) |
| Push to a branch matching `release_branches` | Yes | SHA |
| Pull request with `publish_on_pr: 'true'` | Yes | SHA |
| Any other event | No, build only | - |

The SHA tag is the full commit SHA with `tag_prefix` and `tag_suffix` applied. For pull requests the action uses the PR head SHA. For merge queues it uses the merge group head SHA. `tag_latest` and `tag_nightly` turn off the `latest` and `nightly` tags.

When the action publishes, it also writes the `cache_to` cache, an SBOM, and provenance attestations, and pushes gzip-compressed layers.
