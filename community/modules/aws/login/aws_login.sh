#!/bin/bash

print_message() {
    message="$1"
    echo "$message"
    echo "$(printf '%*s' "${#message}" '' | tr ' ' '-')"
}

function aws_new_login() {
    profile_name=$1
    profile_duration=$2
    profile_role=$3
    profile_region=$4
    print_message "Login --profile $profile_name"
    saml2aws login --profile $profile_name --session-duration $profile_duration --force --role $profile_role --skip-prompt -r $profile_region || true
    print_message "Update kubeconfig --profile $profile_name"
    aws --profile $profile_name eks --region $profile_region update-kubeconfig --name $profile_name || true
}

function aws_login() {
    export SAML2AWS_MFA_TOKEN=${1}
    if [ "${1}" == "" ]; then
        read -p "Type your OTP: " token
        export SAML2AWS_MFA_TOKEN=${token}
    fi
    while IFS= read -r profile_data; do
        echo "Profile: $profile_data"
        IFS=';' read -r -a profile_data_array <<< "$profile_data"
        profile_name=${profile_data_array[0]}
        profile_duration=${profile_data_array[1]}
        profile_role=${profile_data_array[2]}
        profile_region=${profile_data_array[3]}
        aws_new_login $profile_name $profile_duration $profile_role $profile_region
    done < ./data/modules/community/aws/aws_profiles.txt
}
