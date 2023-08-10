#!/usr/bin/env bash
set -e

DOCKER_PHP_REPO="brabholdsa/php"
DOCKER_PHP_DEV_REPO="brabholdsa/php-dev"
GREEN='\033[0;32m' # Green color
NC='\033[0m' # No color
php_version=${1}
build_arg=""

if [[ ! -z "${2}" ]]; then
    build_arg="--build-arg http_proxy=${2} --build-arg https_proxy=${2}"
fi

project_path=$(pwd)/..

for i in docker-php docker-php-dev; do
  pushd ${project_path}/${i}/${php_version}
  echo -e "${GREEN}Current dir: $(pwd)${NC}"

  if [[ ${i} =~ 'dev' ]]; then
    docker_repo=${DOCKER_PHP_DEV_REPO}
  else
    docker_repo=${DOCKER_PHP_REPO}
  fi

  for j in apache cli fpm; do
    tag=${php_version}-${j}
    echo -e "${GREEN}Building ${docker_repo}:${tag}${NC}"
    docker build --no-cache ${build_arg} -t ${docker_repo}:${tag} ${j}
    docker push ${docker_repo}:${tag}
  done
done
