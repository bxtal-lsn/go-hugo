# Sev dev documentation with Hugo

## Spin up local server
Clone repository from 10.249.84.59:3000/sev/documentation

To develop locally before pushing to main, run `hugo server -D` in the root of the repository
A local website spins up at localhost:1313.

Any changes made to a .md file will immediately be available at localhost:1313.

## Developing Documentation
Any new documentation is created at content/docs 

```
content/
├── _index.md                  # Site home page
├── docs/                      # Documentation root (home page)
│   ├── system-administration/       # Main folder
│   │   ├── _index.md          # Section landing page
│   │   ├── installation.md
│   │   └── configuration/     # Nested folder
│   │       ├── _index.md
│   │       ├── basic.md
│   │       └── advanced.md
│   ├── api-reference/         # Main folder
│   │   ├── _index.md
│   │   ├── endpoints.md
│   │   ├── authentication.md
│   │   └── examples/          # Nested folder
│   │       ├── _index.md
│   │       └── basic-requests.md
│   └── deployment/            # Main folder
│       ├── _index.md
│       ├── docker.md
│       ├── kubernetes.md
│       └── ci-cd.md
└── posts/                     # Other content type (not documentation)
    └── ...
```
