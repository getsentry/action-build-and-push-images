# action-build-and-push-images

This is a composite GitHub action that builds and publishes images to

- GitHub Container Registry (GHCR)
- Google Artifact Registry (GAR)

## Usage

### Required Permissions

Add the following permissions block to your workflow to allow publishing to GHCR and/or GAR:

```yaml
permissions:
  contents: read
  packages: write      # Required for GHCR
  id-token: write      # Required for Google Artifact Registry (GAR)
```

If you're just building, `packages` should be set to `read` and `id-token` should be omitted.`

```yaml
permissions:
  contents: read
  packages: read      # Required to read from GHCR if using as cache
  # id-token is omitted here
```

> Adjust permissions as needed for your use case. See [GitHub Actions permissions docs](https://docs.github.com/en/actions/using-jobs/assigning-permissions-to-jobs) for more details.

### Basic Usage

```yaml
- name: Build and push image
  uses: getsentry/action-build-and-push-images@sha
  with:
    image_name: 'sentry'
    platforms: 'linux/amd64'
```

### Multi-Architecture with Matrix Strategy

```yaml
jobs:
  build:
    strategy:
      matrix:
        include:
          - platforms: linux/amd64
            runner: ubuntu-latest
          - platforms: linux/arm64
            runner: ubuntu-latest-arm64
    runs-on: ${{ matrix.runner }}
    steps:
      - name: Build and push image
        uses: getsentry/action-build-and-push-images@sha
        with:
          image_name: 'sentry'
          platforms: ${{ matrix.platforms }}
```

### With Custom Build Configuration

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
| `release_branches` | Release branch names, separated by commas | No | `release,releases` |
| `ghcr` | Enable GitHub Container Registry | No | `true` |
| `ghcr_image_name` | GHCR image name | No | `ghcr.io/{owner}/{image_name}` |
| `publish_on_pr` | Publish images on pull requests (SHA tags only) | No | `false` |
| `google_ar` | Enable Google Artifact Registry | No | `false` |
| `google_ar_image_name` | GAR image name | No | - |
| `tag_prefix` | Tag prefix | No | - |
| `tag_suffix` | Tag suffix | No | - |
| `tag_nightly` | Tag suffix | No | true |
| `tag_latest` | Tag suffix | No | true |
| `google_workload_identity_provider` | Google Workload Identity Provider | No | - |
| `google_service_account` | Google Service Account | No | - |
| `platforms` | Platforms to build (e.g., linux/amd64, linux/arm64) | No | `linux/amd64` |
| `outputs` | List of output destinations (e.g., type=docker, type=image,name=myimage) | No | - |

## Action Outputs

| Output | Description |
|--------|-------------|
| `ghcr_image_url` | Full GHCR image URL with primary tag |
| `gar_image_url` | Full GAR image URL with primary tag |

### Using Outputs

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

## Publishing Behavior

### GitHub Container Registry (GHCR)

- **Push to default branch**: Creates SHA-tagged + nightly images
- **Pull requests**: Creates SHA-tagged image (if `publish_on_pr: 'true'`)
- **All other pushes**: No publishing (build-only)

### Google Artifact Registry (GAR)

- **Push to default branch only**: Creates SHA-tagged images (no nightly)
- **All other events**: No publishing
