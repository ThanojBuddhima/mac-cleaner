# Mac Cleaner

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

A safe, conservative macOS cleanup utility built entirely in Bash.

## Table of Contents
- [Features](#features)
- [Quick Install](#quick-install)
- [Usage](#usage)
- [Uninstall](#uninstall)
- [Architecture](#architecture)
- [Logging](#logging)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Interactive CLI Menu**: Easily navigate and select what you want to clean.
- **Dry-run Mode**: Run `mac-cleaner clean --dry-run` to see what will happen without actually deleting anything.
- **Conservative Deletions**: We explicitly refuse to delete protected system paths. We scan and let you pick.
- **Granular Control**: Clean specific segments of "System Data" safely:
  - User and System Caches
  - Xcode DerivedData and Archives
  - Homebrew and npm caches
  - Time Machine Snapshots
  - Old iOS Device Backups
  - Docker images/containers

## Quick Install

You can easily download and install the tool globally so that it can be run from anywhere in your terminal by running this single command:

```bash
curl -sL https://raw.githubusercontent.com/ThanojBuddhima/SystemDataCleaner/main/install.sh | bash
```

Once installed, simply type `mac-cleaner` in your terminal to start the app.

## Usage

Start the interactive menu:
```bash
mac-cleaner
```

Run a module in dry-run mode:
```bash
mac-cleaner clean --dry-run
```

## Uninstall

If you wish to remove the tool from your system, run the following commands:

```bash
sudo rm /usr/local/bin/mac-cleaner
rm -rf ~/.mac-cleaner
```

## Architecture

This project is built using a modular structure in `src/`:
- `scanner.sh`: Logic for estimating disk usage.
- `common.sh`: Common text styling and UI functions.
- `cleanup.sh`: Centralized logic for deleting files, ensuring dry-runs and system protections.
- Separate modules (`caches.sh`, `developer.sh`, `snapshots.sh`, etc.) contain specific cleanup logic.

## Logging

All deletions and actions are logged to `~/Library/Logs/mac-cleaner.log`.

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

Distributed under the MIT License. See `LICENSE` for more information.
