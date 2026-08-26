# Scripts

This folder is the root scripts directory for the repository. It is organized into subfolders
by purpose so that template-provided tooling and repo-specific scripts remain clearly separated.

## Subfolders

| Folder | Purpose |
| ------ | ------- |
| [`template/`](template/) | Template-provided scripts for bootstrap, linting, hook installation, and workspace normalization. These scripts are part of the repository template and should not be modified for repo-specific purposes. |

## Adding Repo-Specific Scripts

When creating scripts specific to the code in this repository (for example, build helpers,
deployment scripts, or service-specific automation), place them in a purpose-named subfolder
such as `scripts/runtime/` or `scripts/ci/`.

This keeps template tooling and project tooling clearly separated and avoids confusion for
maintainers.

Example layout for a repo that extends this template:

```text
scripts/
├── template/       # Template-provided tooling (do not modify)
│   ├── install-hooks.sh
│   ├── lint-docs.sh
│   └── ...
└── runtime/        # Repo-specific scripts (add yours here)
    ├── build.sh
    └── deploy.sh
```
