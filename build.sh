#!/usr/bin/env bash
set -e

set_env() {
  if [ -f "${1}" ]; then
    source ${1}
  fi
}

unset_env() {
  if [ -f "${1}" ]; then
    unset $(grep -v '^#' ${1} | awk 'BEGIN { FS = "=" } ; { print $1 }')
  fi
}

building_message() {
  echo -e "\033[0;32mBuilding ${1} from ${2}\033[0m"
}

php_version=${1:-"8.3"}
project_path="$(pwd)/.."

for i in apache cli; do
  tag=${php_version}-${i}

  # php-prod
  pushd "${project_path}/docker-php"
  set_env ${php_version}.env
  php_base_image="yannickvh/php-prod:${tag}"
  php_prod_image_tag="brabholdsa/php:${tag}"
  building_message ${php_prod_image_tag} ${php_base_image}
  docker build \
    --no-cache \
    --tag "${php_prod_image_tag}" \
    --build-arg PHP_BASE_IMAGE="${php_base_image}" \
    --build-arg WKHTMLTOPDF_URL="${WKHTMLTOPDF_URL}" \
    .
  docker push ${php_prod_image_tag}

  # php-prod imagick
  imagick_prod_image_tag="${php_prod_image_tag}-imagick"
  building_message ${imagick_prod_image_tag} ${php_prod_image_tag}
  docker build \
    --no-cache \
    --tag ${imagick_prod_image_tag} \
    --build-arg PHP_BASE_IMAGE="${php_prod_image_tag}" \
    --file "Dockerfile.imagick" \
    .
  docker push ${imagick_prod_image_tag} 
  unset_env ${php_version}.env
  popd > /dev/null

  # php-dev
  pushd "${project_path}/docker-php-dev"
  set_env ${php_version}.env
  php_dev_image_tag="brabholdsa/php-dev:${tag}"
  building_message ${php_dev_image_tag} ${php_prod_image_tag}
  docker build \
    --no-cache \
    --tag "${php_dev_image_tag}" \
    --build-arg PHP_BASE_IMAGE="${php_prod_image_tag}" \
    --build-arg NODE_VERSION="${NODE_VERSION}" \
    .
  docker push ${php_dev_image_tag}

  # php-dev imagick
  imagick_dev_image_tag="${php_dev_image_tag}-imagick"
  building_message ${imagick_dev_image_tag} ${imagick_prod_image_tag}
  docker build \
    --no-cache \
    --tag "${imagick_dev_image_tag}" \
    --build-arg PHP_BASE_IMAGE="${imagick_prod_image_tag}" \
    --build-arg NODE_VERSION="${NODE_VERSION}" \
    .
  docker push ${imagick_dev_image_tag}
  unset_env ${php_version}.env
  popd > /dev/null
done
