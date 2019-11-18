#!/bin/bash
echo "DateTime:" $(date +"%Y-%m-%d %H:%M:%S")

. /etc/container_environment.sh

if [ -z "$GIT_USERNAME" ]; then echo 'GIT_USERNAME environment variable is not set!'; exit 1; fi
if [ -z "$GIT_EMAIL" ]; then echo 'GIT_EMAIL environment variable is not set!'; exit 1; fi
if [ -z "$BUCKET" ]; then echo 'BUCKET environment variable is not set!'; exit 1; fi
if [ -z "$REMOTE_HOST" ]; then 'REMOTE_HOST environment variable is not set!'; exit 1; fi
if [ -z "$SCOOP_HOME" ]; then echo 'SCOOP_HOME environment variable is not set!'; exit 1; fi
if [ $METHOD != 'push' ]; then
    if [ -z $UPSTREAM ]; then echo 'UPSTREAM environment variable is not set!'; exit 1; fi
fi

find /root/log/*.log -mtime +2 -exec rm {} \;

if [ ! -f /root/first_run ]; then
    # Update CRONTAB
    if [ ! -z "$CRONTAB" ]; then
        echo "$CRONTAB root /bin/bash /root/excavate.sh > /root/log/mud-\$(date +\"\%Y\%m\%d-\%H\%M\%S\").log 2>&1" > /etc/cron.d/excavator
    fi

    # Set git config settings
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"

    # add github.com to known_hosts and generate private/public key
    . /root/init_ssh.sh

    # Clone bucket and add remotes
    if [ ! -d /root/bucket ]; then
        echo 'Initializing Bucket repository ...'
        git config --global core.autocrlf true
        git clone "https://$REMOTE_HOST/$BUCKET" /root/bucket
        cd /root/bucket
        git remote set-url --push origin "git@$REMOTE_HOST:$BUCKET.git"
        if [ $METHOD != 'push' ]; then
            git remote add upstream "git@$REMOTE_HOST:$UPSTREAM.git"
        fi
    fi

    # first run complete
    touch /root/first_run
fi

echo 'Updating Scoop ...'
cd /root/scoop
git pull

echo 'Cleaning Scoop cache ...'
cd /root/bucket
rm /root/cache/* 2> /dev/null

echo 'Excavating ...'
ARGS=
if [ $METHOD == 'push' ]; then
    ARGS="-Push"
else
    ARGS="-Request"
fi

if [ ! -z $SNOWFLAKES ]; then
    ARGS="$ARGS -SpecialSnowflakes $SNOWFLAKES"
fi

if [ "$REMOTE_HOST" = 'github.com' ]; then
    if [ -f /root/bucket/bin/auto-pr.ps1 ]; then
        pwsh /root/bucket/bin/auto-pr.ps1 $ARGS
    fi
    if [ -f /root/bucket/bin/bucket-updater.ps1 ]; then
        pwsh /root/bucket/bin/bucket-updater.ps1 $ARGS
    fi
else
    if [ -f /root/bucket/bin/checkver.ps1 ]; then
        echo 'Updating each manifests ...'
        cd /root/bucket
        auto_commit() {
            local json=$1
            local name=$(echo -n $json | sed 's/\.[^\.]*$//')
            local ver=$(jq -r '.version' $json)
            local msg=$(printf '%s: Update to version %d' $name $ver)
            pwsh /root/bucket/bin/checkver.ps1 -u $json
            [ -z $(git status -s) ] && return
            git add $json
            git commit -m $msg
            [ $? -ne 0 ] && git checkout .
        }
        export -f auto_commit
        find *.json | xargs -I % bash -c "auto_commit" %

        if [ ! -z $(git status -bs | head -n1 | sed -E 's/[^0-9]*//g') ]; then
            echo 'Pushing updates ...'
            if [ -f /root/first_push ]; then
                git push origin master
            else
                git push -u origin master
                touch /root/first_push
            fi
        else
            echo 'All manifests are up to date.'
        fi
    fi
fi

