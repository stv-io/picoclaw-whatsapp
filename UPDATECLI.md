# UpdateCLI Configuration

This repository uses [UpdateCLI](https://www.updatecli.io/) to automatically keep the PicoClaw version up-to-date.

## How it works

UpdateCLI monitors the PicoClaw GitHub repository for new releases and automatically updates all references to the PicoClaw version in this repository.

### What gets updated

When a new PicoClaw version is released, UpdateCLI automatically updates:

1. **Dockerfile** - PicoClaw git checkout version and build version strings
2. **Dockerfile.native** - PicoClaw git checkout version and build version strings  
3. **Makefile** - `PICOCLAW_VERSION` variable
4. **README.md** - Docker pull commands, Kubernetes examples, and image tags documentation

### What doesn't need updating

- **GitHub Actions workflow** - Dynamically extracts version from Dockerfile, so no manual updates needed

## Running UpdateCLI

### Automated

UpdateCLI runs automatically:
- **Every Monday at 09:00 UTC** via GitHub Actions scheduled workflow
- **On-demand** by triggering the `updatecli` workflow manually

### Manual

You can also run UpdateCLI locally:

```bash
# Install UpdateCLI
brew install updatecli

# Run in dry-run mode to see what would change
updatecli diff --config updatecli.yaml

# Apply changes (requires GITHUB_TOKEN)
export GITHUB_TOKEN=your_token
updatecli apply --config updatecli.yaml
```

## Configuration

The UpdateCLI configuration is in `updatecli.yaml`:

- **Source**: Monitors PicoClaw GitHub releases
- **Targets**: Updates version references in multiple files
- **Action**: Creates pull requests with automatic labeling

## Pull Request Process

When UpdateCLI detects a new version:

1. Creates a pull request with title: `chore: Update PicoClaw to v{version}`
2. Includes detailed description of changes
3. Labels with `dependencies` and `picoclaw-update`
4. Uses squash merge method

## Testing

You can test the pattern matching with the provided test script:

```bash
./test-updatecli.sh
```

This verifies that all UpdateCLI patterns correctly match the current files.

## Version Format

PicoClaw versions follow the format: `v{picoclaw-version}-whatsapp.{whatsapp-tool-version}`

- **PicoClaw Version**: Automatically updated from upstream releases
- **WhatsApp Version**: Manually managed (currently 1.0)

## Troubleshooting

If UpdateCLI fails:

1. Check that patterns in `updatecli.yaml` match the actual file content
2. Run the test script to verify pattern matching
3. Check GitHub Actions logs for detailed error messages
4. Ensure GITHUB_TOKEN has proper permissions for creating pull requests
