#!/bin/bash

set -e -u -o pipefail

[[ $# -eq 0 ]] && echo "Please Pass a Settings File Path" && exit 1

settings_file=$1

mirror_dir="./mirror"
working_dir=$(pwd)
mkdir -p ${mirror_dir}/terraform ${mirror_dir}/terragrunt

download_terraform(){
  local terraform_version=$1
  local platform=$2
  local file_name=terraform_${terraform_version}_${platform}.zip
  local url=https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_${platform}.zip

  echo "Downloading Terraform version ${terraform_version} for ${platform}"
  curl -Lo "${working_dir}/${mirror_dir}/terraform/${file_name}" "${url}"
}

download_terragrunt(){
  local terragrunt_version=$1
  local platform=$2
  local file_extension=$(echo ${platform} | sed -r "s/windows_(.*)/${platform}.exe/")
  local file_name=terragrunt_${terragrunt_version}_${file_extension}
  local url=https://github.com/gruntwork-io/terragrunt/releases/download/v${terragrunt_version}/terragrunt_${file_extension}

  echo "Downloading Terragrunt version ${terragrunt_version} for ${platform}"
  curl -Lo "${working_dir}/${mirror_dir}/terragrunt/${file_name}" "${url}"
}

download_providers(){
  local provider_namespace=$1
  local provider_name=$2
  local provider_version=$3
  local platform=$4

  echo "Downloading Terraform Provider ${provider_namespace}/${provider_name}:${provider_version}"
  cat > main.tf << EOF
terraform {
  required_providers {
    ${provider_name} = {
      source  = "${provider_namespace}/${provider_name}"
      version = "${provider_version}"
    }
  }
}
EOF
  terraform providers mirror -platform=${platform} ./
  rm main.tf
}

settings_json=$(cat ${settings_file})
terraform_versions=$(echo ${settings_json} | jq '[.terraform[]]')
terragrunt_versions=$(echo ${settings_json} | jq '[.terragrunt[]]')
platforms=$(echo ${settings_json} | jq '[.platforms[]]')
providers=$(echo ${settings_json} | jq '[ .providers[] ]')
provider_names=$(echo ${settings_json} | jq '[ .providers[].name ]')

echo
echo "Mirror Settings:"
echo "  Terraform Versions:     ${terraform_versions}"
echo "  Platforms:         ${platforms}"
echo "  Providers:         ${provider_names}"
echo

cd ${mirror_dir}

echo "Downloading Terraform Versions Locally"

for version in $(echo ${terraform_versions} | jq -r '.[]'); do
  for platform in $(echo ${platforms} | jq -r '.[]'); do
      #download_terraform $version $platform
      echo TERRAFORM
  done
done

echo "Downloading Terragrunt Versions Locally"

echo ${terragrunt_versions}

for version in $(echo ${terragrunt_versions} | jq -r '.[]'); do
  for platform in $(echo ${platforms} | jq -r '.[]'); do
      download_terragrunt $version $platform
  done
done

echo "Downloading Providers Locally"

for row in $(echo ${providers} | jq -r '.[] | [.namespace, .name, .versions] | @base64'); do
  _namespace() {
    echo ${row} | base64 --decode | jq -r .[0]
  }
  _name() {
    echo ${row} | base64 --decode | jq -r .[1]
  }
  _versions() {
    echo ${row} | base64 --decode | jq -r .[2]
  }

  # echo $(_name) $(_versions)
  for version in $(_versions | jq -r '.[]'); do
    ns=$(_namespace)
    n=$(_name)

    for platform in $(echo ${platforms} | jq -r '.[]'); do
      #download_providers $ns $n $version $platform
      echo PROVIDERS
    done
  done
done
