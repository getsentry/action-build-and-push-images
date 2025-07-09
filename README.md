# action-build-and-push-images

This is a composite GitHub action that builds and publishes images to

- GitHub Container Registry (GHCR)
- Google Artifact Registry (GAR)

## Usage

### Basic Usage

```yaml
- name: Build and push image
  uses: getsentry/action-build-and-push-images@sha
  with:
    image_name: 'sentry'
    architecture: 'amd64'
```

### Multi-Architecture with Matrix Strategy

```yaml
jobs:
  build:
    strategy:
      matrix:
        include:
          - architecture: amd64
            runner: ubuntu-latest
          - architecture: arm64
            runner: ubuntu-latest-arm64
    runs-on: ${{ matrix.runner }}
    steps:
      - name: Build and push image
        uses: getsentry/action-build-and-push-images@sha
        with:
          image_name: 'sentry'
          architecture: ${{ matrix.architecture }}
```

### With Custom Build Configuration

```yaml
- name: Build and push image
  uses: getsentry/action-build-and-push-images@sha
  with:
    image_name: 'sentry'
    architecture: 'amd64'
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
    architecture: 'amd64'

    # Enable GAR publishing
    google_ar: 'true'
    google_ar_image_name: 'us-central1-docker.pkg.dev/myproject/myrepo/myapp'
    google_ar_tag_prefix: 'v'  # Optional: prefix for tags (e.g., v1.2.3)

    # Authentication (required for GAR)
    google_workload_identity_provider: 'projects/123/locations/global/workloadIdentityPools/pool/providers/provider'
    google_service_account: 'service-account@project.iam.gserviceaccount.com'
```


## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `image_name` | Base image name | Yes | - |
| `architecture` | Architecture to build (amd64, arm64) | No | `amd64` |
| `dockerfile_path` | Path to Dockerfile | No | `./Dockerfile` |
| `build_context` | Build context directory | No | `.` |
| `build_target` | Docker build target stage | No | - |
| `build_args` | Docker build arguments (multiline) | No | - |
| `ghcr` | Enable GitHub Container Registry | No | `true` |
| `ghcr_image_name` | GHCR image name | No | `ghcr.io/{owner}/{image_name}` |
| `publish_on_pr` | Publish images on pull requests | No | `false` |
| `google_ar` | Enable Google Artifact Registry | No | `false` |
| `google_ar_image_name` | GAR image name | No | - |
| `google_ar_tag_prefix` | GAR tag prefix | No | - |
| `google_workload_identity_provider` | Google Workload Identity Provider | No | - |
| `google_service_account` | Google Service Account | No | - |
| `cache_enabled` | Enable build cache | No | `true` |
| `cache_suffix` | Cache image suffix | No | `cache` |

## Publishing Behavior

### GitHub Container Registry (GHCR)

- **Any push**: Creates SHA-tagged image
- **Push to main/master**: Creates SHA-tagged + latest images
- **Pull requests**: Creates SHA-tagged image (if `publish_on_pr: 'true'`)

### Google Artifact Registry (GAR)

- **Push to main/master only**: Creates SHA-tagged image
- **All other events**: No publishing
