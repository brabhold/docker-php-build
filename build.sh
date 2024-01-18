#!/usr/bin/env bash
set -e

DOCKER_PHP_REPO="brabholdsa/php"
DOCKER_PHP_DEV_REPO="brabholdsa/php-dev"
GREEN='\033[0;32m' # Green color
NC='\033[0m' # No color
php_version=${1:-"8.3"}
debian=${2:-"bookworm"}

project_path="$(pwd)/.."

for i in docker-php docker-php-dev; do
  pushd "${project_path}/${i}"
  echo -e "${GREEN}Current dir: $(pwd)${NC}"

  if [[ ${i} =~ 'dev' ]]; then
    docker_repo=${DOCKER_PHP_DEV_REPO}
    base_org=${DOCKER_PHP_REPO}
  else
    docker_repo=${DOCKER_PHP_REPO}
    base_org="yannickvh/php-prod"
  fi

  for j in apache cli; do
    tag="${php_version}-${j}"
    echo -e "${GREEN}Building ${docker_repo}:${tag}${NC}"
    docker build --no-cache --tag "${docker_repo}:${tag}" --build-arg PHP_BASE_IMAGE="${base_org}:${tag}" --file "${debian}/${j}/Dockerfile" .
    docker push "${docker_repo}:${tag}"

    imagick_tag="${docker_repo}:${tag}-imagick"

    if [[ ${i} =~ 'dev' ]]; then
      imagick_base_image="${DOCKER_PHP_REPO}:${tag}-imagick"
      imagick_path="${debian}/${j}"
    else
      imagick_base_image="${docker_repo}:${tag}"
      imagick_path="imagick"
    fi
    
    echo -e "${GREEN}Building ${imagick_tag}${NC}"
    docker build --no-cache --tag ${imagick_tag} --build-arg PHP_BASE_IMAGE=${imagick_base_image} --file "${imagick_path}/Dockerfile" .
    docker push "${docker_repo}:${tag}"
  done
done
