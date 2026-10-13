# Changelog

## Unreleased

- Skip QEMU setup when every requested platform matches the runner's native architecture. This avoids pulling and caching the binfmt image for native builds.
- Add `cache_from` and `cache_to` inputs so callers can change or disable the BuildKit cache.
- Authenticate Docker to Google Artifact Registry with a short-lived WIF access token instead of writing a credentials file and running `gcloud auth configure-docker`.
