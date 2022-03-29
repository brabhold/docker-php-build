#!/usr/bin/env bash
set -e

DOCKER_PHP_REPO="brabholdsa/php"
DOCKER_PHP_DEV_REPO="brabholdsa/php-dev"
LAST_PHP_VERSION="8.1"
php_version=$1
git_branch=$1
build_arg=""

if [[ ! -z "$2" ]]; then
    build_arg="--build-arg http_proxy=$2 --build-arg https_proxy=$2"
fi

if [[ $php_version = $LAST_PHP_VERSION ]]; then
  git_branch="main"
fi

for i in docker-php docker-php-dev; do
  cd ../$i
  echo "Current dir: " $(pwd)
  git fetch
  git checkout $git_branch

  if [[ $i =~ 'dev' ]]; then
    docker_repo=$DOCKER_PHP_DEV_REPO
  else
    docker_repo=$DOCKER_PHP_REPO
  fi

  for j in apache cli fpm; do
    tag=$php_version-$j
    echo "Build $docker_repo:$tag"
    docker build --no-cache $build_arg -t $docker_repo:$tag $j
    docker push $docker_repo:$tag
  done

  git checkout -
done
