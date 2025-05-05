#!/usr/bin/env bash
set -e

building_message() {
  echo -e "\033[0;32mBuilding ${1} from ${2}\033[0m"
}

php_version=${1:-"8.3"}
targets=${2:-"apache cli"}
build_path=$(pwd)
project_path="$(pwd)/.."

source ${php_version}.env

for target in ${targets}; do
  tag=${php_version}-${target}

  # php-prod
  pushd "${project_path}/docker-php"
  php_prod_image_tag="brabholdsa/php:${tag}"
  building_message ${php_prod_image_tag} amd64/debian:bookworm-slim
  docker build \
    --quiet \
    --target ${target} \
    --tag "${php_prod_image_tag}" \
    --build-arg PHP_VERSION="${php_version}" \
    .
  docker push ${php_prod_image_tag}

  # php-prod imagick
  imagick_prod_image_tag="${php_prod_image_tag}-imagick"
  building_message ${imagick_prod_image_tag} ${php_prod_image_tag}
  docker build \
    --quiet \
    --tag ${imagick_prod_image_tag} \
    --build-arg PHP_BASE_IMAGE="${php_prod_image_tag}" \
    --build-arg PHP_VERSION="${php_version}" \
    --file "Dockerfile.imagick" \
    .
  docker push ${imagick_prod_image_tag} 
  popd > /dev/null

  # php-dev
  pushd "${project_path}/docker-php-dev"
  php_dev_image_tag="brabholdsa/php-dev:${tag}"
  building_message ${php_dev_image_tag} ${php_prod_image_tag}
  docker build \
    --quiet \
    --tag "${php_dev_image_tag}" \
    --build-arg PHP_BASE_IMAGE="${php_prod_image_tag}" \
    --build-arg PHP_VERSION="${php_version}" \
    --build-arg NODE_VERSION="${NODE_VERSION}" \
    .
  docker push ${php_dev_image_tag}

  # php-dev imagick
  imagick_dev_image_tag="${php_dev_image_tag}-imagick"
  building_message ${imagick_dev_image_tag} ${imagick_prod_image_tag}
  docker build \
    --quiet \
    --tag "${imagick_dev_image_tag}" \
    --build-arg PHP_BASE_IMAGE="${imagick_prod_image_tag}" \
    --build-arg PHP_VERSION="${php_version}" \
    --build-arg NODE_VERSION="${NODE_VERSION}" \
    .
  docker push ${imagick_dev_image_tag}
  popd > /dev/null
done

unset $(grep -v '^#' ${php_version}.env | awk 'BEGIN { FS = "=" } ; { print $1 }')
