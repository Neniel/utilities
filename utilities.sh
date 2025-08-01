#!/bin/bash

set -e

COMMAND=$1
ACTION=$2
CACHE="./data/.cache"

function error() {
  echo "Error: $1" >&2
  exit 1
}

function repo_update() {
  git checkout main
  git fetch --all --prune
  git pull --rebase
}

function repo_change() {
  repo_update
  read -p "What are you going to do?: " description
  if [[ -z "$description" ]]; then
    error "Description cannot be empty"
  fi
  lowercase_description=$(echo "$description" | tr '[:upper:]' '[:lower:]')
  formatted_description=$(echo "$lowercase_description" | tr ' ' '-')
  git checkout -b "$formatted_description"
}

case "$COMMAND" in
  aws)
    case "$ACTION" in
      login)
        source ./modules/community/aws/login/aws_login.sh
        aws_login $3
        ;;
      profile)
        case "$3" in
          add)
            source ./modules/community/aws/profile/add/aws_profile_add.sh
            profile_data=$(aws_profile_add)
            IFS=';' read -r -a profile_data_array <<< "$profile_data"
            echo "${profile_data_array[@]}"
            source ./modules/community/aws/login/aws_login.sh
            aws_new_login "${profile_data_array[0]}" "${profile_data_array[1]}" "${profile_data_array[2]}" "${profile_data_array[3]}"
            ;;
          list)
            cat ./data/modules/community/aws/aws_profiles.txt
            ;;
          *)
            echo "Usage: $0 aws profile [add|list]"
            exit 1
            ;;
        esac
        ;;
      *)
        echo "Usage: $0 aws [login|profile]"
        exit 1
        ;;
    esac
    ;;
  repo)
    case "$ACTION" in
      add)
        if [[ -z "$3" ]]; then
          error "Repo name cannot be empty"
        fi

        if [ ! -s "$CACHE" ]; then
            touch "$CACHE"
        fi
        
        declare -a cache_data
        readarray -t cache_data < "$CACHE"

        read -p "Version Control System$( [ -n "${cache_data[0]}" ] && printf " [%s]" "${cache_data[0]}" ): " version_control_system
        if [[ -z "$version_control_system" ]]; then
          version_control_system=${cache_data[0]}
        fi

        read -p "Team Workspace$( [ -n "${cache_data[1]}" ] && printf "[%s]" "${cache_data[1]}" ): " team_workspace
        if [[ -z "$team_workspace" ]]; then
          team_workspace=${cache_data[1]}
        fi

        echo "$version_control_system" > "$CACHE"
        echo "$team_workspace" >> "$CACHE"

        git clone "git@$version_control_system:$team_workspace/$3.git" ~/$version_control_system/$team_workspace/
        ;;
      update)
        repo_update
        ;;
      work)
        repo_change
        ;;
      *)
        echo "Usage: $0 repo [add|update|work]"
        exit 1
        ;;
    esac
    ;;
  --version)
    cat .version
    ;;
  module)
    case "$ACTION" in
      upsert)
        if [[ -z "$3" ]]; then
          error "Module name cannot be empty"
        fi

        if [ ! -d  "./community/modules/$3" ]; then
          error "Module $3 does not exist"
        fi
        rm -rf ./modules/community/$3
        rsync -a \
          --exclude 'README.md' \
          ./community/modules/$3/ ./modules/community/$3/
        ;;
      *)
        echo "Usage: $0 module [upsert]"
        exit 1
        ;;
    esac
    ;;
  onboarding)
    read -p "Version Control System [github.com]: " vcs
    vcs=$(echo "$vcs" | tr '[:upper:]' '[:lower:]')
    if [[ -z "$vcs" ]]; then
      vcs="github.com"
    fi

    read -p "Team Workspace: " team_workspace
    if [[ -z "$team_workspace" ]]; then
      error "Team Workspace cannot be empty"
    fi

    mkdir -p ~/$vcs/$team_workspace

    IFS='.' read -r vcs_name vcs_domain <<< "$vcs"

    read -p "What's your name?: " name
    if [[ -z "$name" ]]; then
      error "Name cannot be empty"
    fi

    read -p "What's your email?: " email
    if [[ -z "$email" ]]; then
      error "Email cannot be empty"
    fi

    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519_"$vcs_name"_"$team_workspace"

    cat ~/.ssh/id_ed25519_"$vcs_name"_"$team_workspace".pub 

    gpg --full-generate-key

    cat <<EOF >> ~/.gitconfig
[includeIf "gitdir:~/$vcs/$team_workspace/"]
    path = ~/.gitconfig-$vcs_name-$team_workspace
EOF

    cat <<EOF > ~/.gitconfig-$vcs_name-$team_workspace
[url "ssh://git@$vcs/"]
        insteadOf = https://$vcs/

[user]
        email = $email
        name = $name
        signingkey = C2933F5C9ADB2151

[commit]
        gpgsign = true

[tag]
        gpgSign = true

[core]
        sshCommand = "ssh -i ~/.ssh/id_ed25519_"$vcs_name"_"$team_workspace" -F /dev/null"
EOF

    ;;
  *)
    echo "Usage: $0 [aws|repo]"
    exit 1
    ;;
esac
