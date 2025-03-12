# Documentation with Hugo

## Spin up local server
Clone repository from 10.249.84.59:3000/sev/documentation

To develop locally before pushing to main, run `hugo server -D` in the root of the repository
A local website spins up at `localhost:1313`.

Any changes made to a .md file will immediately be available at `localhost:1313`.

## Developing Documentation
Any new documentation is created at content/docs 
see diagram
```
.
├── _index.md
└── docs
   ├── data-engineering-and-pipelines
   │  ├── _index.md
   │  └── data-pipelines
   │     ├── _index.md
   │     └── billing.md
   ├── installation-and-deployment
   │  ├── _index.md
   │  ├── ansible
   │  │  ├── _index.md
   │  │  └── ansible-guide.md
   │  ├── docker
   │  │  ├── _index.md
   │  │  ├── building-minimal-go-docker-images.md
   │  │  ├── deploy-private-docker-registry.md
   │  │  ├── docker-engine-not-starting-WSL-update-failed-error.md
   │  │  ├── install-docker-on-oracle-linux.md
   │  │  └── swarm-mode-guide.md
   │  ├── gitea
   │  │  ├── _index.md
   │  │  └── gitea-guide.md
   │  ├── harbor
   │  │  ├── _index.md
   │  │  └── harbor-guide.md
   │  ├── hashicorp
   │  │  ├── _index.md
   │  │  ├── vagrant-and-virtualbox-guide.md
   │  │  └── vault-guide.md
   │  ├── linux
   │  │  ├── _index.md
   │  │  ├── caddy-web-server-guide.md
   │  │  ├── gnu-stow-guide.md
   │  │  ├── golang-installation.md
   │  │  └── multipass-guide.md
   │  └── trino
   │     ├── _index.md
   │     └── trino-guide.md
   ├── programming-and-development
   │  ├── _index.md
   │  ├── golang
   │  │  ├── _index.md
   │  │  ├── go-migrate.md
   │  │  ├── go-mod-vendor.md
   │  │  └── viper-configuration-management.md
   │  └── python
   │     ├── _index.md
   │     └── python-certificate-error-hotfix.md
   ├── projects
   │  └── _index.md
   └── system-administration
      ├── _index.md
      ├── linux
      │  ├── _index.md
      │  ├── add-certificate-to-wsl-instance.md
      │  ├── disabling-shell-history-on-production-linux-servers.md
      │  ├── linux-server-security-hardening.md
      │  ├── mounting-windows-shares-on-linux-servers.md
      │  ├── oracle-linux-automatic-updates.md
      │  ├── setting-up-secure-service-user-ssh-authentication-between-linux-servers.md
      │  ├── sftp-access-to-remote-linux-servers.md
      │  ├── ssh-access-to-remote-servers.md
      │  └── test.md
      ├── postgres
      │  ├── _index.md
      │  └── postgresql-backup-and-recovery-guide-for-windows.md
      └── powershell
         ├── _index.md
         └── nssm-service-utility.md
```

The title of the .md file will be the title of the path. e.g. `systemd-services.md` will be displayed as `Systemd Services`

When done editing, push the changes to main branch and it will be displayed at 10.249.84.50:3002 (or :5000 until :3002 is accessible from dev machines) 


