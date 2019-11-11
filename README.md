# Excavator-JP

Customized [Excavator](https://github.com/ScoopInstaller/Excavator) (Docker image to update [Scoop](https://scoop.sh/) buckets automatically) for Japanese.

## Usage

1. Add following script:
    - GitHub: `bin\bucket-updater.ps1` to your Bucket (see: [bucket-updater.ps1](#example-binbucket-updaterps1))
    - Bitbucket, GitLab, etc: `bin\checkver.ps1` to your Bucket (see: [checkver.ps1](#example-bincheckverps1))
2. Edit `docker-compose.yml` (see: [docker-compose.yml](#example-docker-composeyml))
3. Run `docker-compose up -d --build`
4. Run `docker-compose exec /root/init_ssh.sh` to generate ssh key
5. Add the generated public key to your remote host service's account (see: ssh volume)

## What's difference?

- Support Bitbucket, GitLab, and more hosting services.
- Set timezone as `Asia/Tokyo`.

## Environment Variables

The following Environment Variables are required for pushing changes to remote repositories.
```
BUCKET=<user>/<repo>        # GitHub/Bitbucket/etc Repo (e.g. lukesampson/scoop)
GIT_USERNAME=               # For "git config user.name"
GIT_EMAIL=                  # For "git config user.email"
CRONTAB=0 * * * *           # Change cron execution times
REMOTE_HOST=                # host address (e.g. github.com)

# Optional:
SNOWFLAKES=curl,brotli      # Programs that should always be updated (comma separated)
METHOD=push                 # push = pushs to $BUCKET (default) / request = pull-request to $UPSTREAM
UPSTREAM=<user>/<repo>      # Upstream GitHub Repo for Pull-Request creating
SCOOP_DEBUG=true            # Enables Scoop debug output
```
## Example `bin\bucket-updater.ps1`

```powershell
param(
    # overwrite upstream param
    [String]$upstream = "<user>/<repo>:master"
)
if(!$env:SCOOP_HOME) { $env:SCOOP_HOME = resolve-path (split-path (split-path (scoop which scoop))) }
$autopr = "$env:SCOOP_HOME/bin/auto-pr.ps1"
$dir = "$psscriptroot/.." # checks the parent dir
iex -command "$autopr -dir $dir -upstream $upstream $($args |% { "$_ " })"
```

## Example `bin\checkver.ps1`

```powershell
if(!$env:SCOOP_HOME) { $env:SCOOP_HOME = resolve-path (split-path (split-path (scoop which scoop))) }
$checkver = "$env:SCOOP_HOME/bin/checkver.ps1"
$dir = "$psscriptroot/../bucket" # checks the parent dir
Invoke-Expression -command "& '$checkver' -dir '$dir' $($args | ForEach-Object { "$_ " })"
```

## Example `docker-compose.yml`

```yaml
version: "3"

services:
  bucket:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ssh:/root/.ssh
      - logs:/root/log
    environment:
      GIT_USERNAME: "Max Muster"
      GIT_EMAIL: "max-muster@gmail.com"
      REMOTE_HOST: "github.com"
      BUCKET: "maxmuster/my-bucket"
      CRONTAB: "0 5 * * *"
volumes:
  ssh:
  logs:
```

## These Scoop buckets get automated updates

- [rkbk60/scoop-for-jp](https://bitbucket.org/rkbk60/scoop-for-jp)

## License

The MIT License (MIT)
