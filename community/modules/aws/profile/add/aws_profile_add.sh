#!/bin/bash

function aws_profile_add() {
    read -p "Profile name: " profile_name
    if [[ -z "$profile_name" ]]; then
        error "Profile name cannot be empty"
    fi
    read -p "Session duration [43200]: " session_duration
    if [[ -z "$session_duration" ]]; then
        session_duration=43200
    fi
    read -p "Role ARN: " role_arn
    if [[ -z "$role_arn" ]]; then
        error "Role ARN cannot be empty"
    fi
    read -p "Region [us-east-1]: " region
    if [[ -z "$region" ]]; then
        region=us-east-1
    fi
    profile="$profile_name;$session_duration;$role_arn;$region"
    echo "$profile" >> ./data/modules/community/aws/aws_profiles.txt
    echo "$profile"
}