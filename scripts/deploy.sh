#!/usr/bin/env bash
set -euo pipefail

function validate_variables() {
  if [ -z "${DEPLOY_ENV-}" ]; then
    echo "DEPLOY_ENV is not set" && exit 10
  fi
  if [ -z "${DEPLOY_TARGET-}" ]; then
    echo "DEPLOY_TARGET is not set" && exit 10
  fi
  if [ -z "${APP_NAME-}" ]; then
    echo "APP_NAME is not set" && exit 10
  fi
  if [ -z "${IMAGE-}" ]; then
    echo "IMAGE is not set" && exit 10
  fi
  if [ -z "${IMAGE_TAG-}" ]; then
    echo "IMAGE_TAG is not set" && exit 10
  fi
}

function print_plan() {
  echo "Deploy plan:"
  echo "Deploy env: $DEPLOY_ENV"
  echo "Deploy target: $DEPLOY_TARGET"
  echo "App name: $APP_NAME"
  echo "Image: $IMAGE:$IMAGE_TAG"
}

function health_check() {
  echo "Health check..."
  echo "-----------------"
  if [ -z "${HEALTH_CHECK_URL-}" ]; then
    echo "HEALTH_CHECK_URL is not set, skip"
    return 0
  fi

  local retries=5
  local i=1
  while [ "$i" -le "$retries" ]; do
    if curl -fsS "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
      echo "Health check passed: $HEALTH_CHECK_URL"
      return 0
    fi
    echo "Attempt $i/$retries failed, retrying..."
    sleep 3
    i=$((i + 1))
  done

  echo "Health check failed after $retries attempts" >&2
  return 1
}

function deploy_ssh() {
  echo "Deploying SSH server..."
  echo "-----------------"
  # 暂无服务器，临时跳过真实 SSH 连接
  # ssh $DEPLOY_USER@$DEPLOY_HOST docker pull $IMAGE:$IMAGE_TAG
  echo "SSH server deployed successfully."
}
function deploy_docker() {
  echo "Deploying Docker container..."
  echo "-----------------"
  # 暂无服务器，临时跳过真实 SSH 连接
  # ssh $DEPLOY_USER@$DEPLOY_HOST docker pull $IMAGE:$IMAGE_TAG
  # ssh $DEPLOY_USER@$DEPLOY_HOST docker stop $APP_NAME || true
  # ssh $DEPLOY_USER@$DEPLOY_HOST docker rm $APP_NAME || true
  # ssh $DEPLOY_USER@$DEPLOY_HOST docker run -d --name $APP_NAME -p 80:80 $IMAGE:$IMAGE_TAG
  
  echo "Docker container deployed successfully."
}
function deploy_ecs() {
  echo "Deploying ECS service..."
  echo "-----------------"
  echo "Deploy env: $DEPLOY_ENV"
  echo "App name: $APP_NAME"
  echo "Image: $IMAGE:$IMAGE_TAG"
  echo "ECS service deployed successfully."
}

main() {
  validate_variables
  print_plan
#   if [ "$DEPLOY_TARGET" = "ssh" ]; then
#     deploy_ssh
#   elif [ "$DEPLOY_TARGET" = "docker" ]; then
#     deploy_docker
#   elif [ "$DEPLOY_TARGET" = "ecs" ]; then
#     deploy_ecs
#   else
#     echo "Invalid deploy target: $DEPLOY_TARGET" && exit 10
#   fi

    case "$DEPLOY_TARGET" in
    ssh)
      deploy_ssh
      ;;
    docker)
      deploy_docker
      ;;
    ecs)
      deploy_ecs
      ;;
    *)
      echo "Invalid deploy target: $DEPLOY_TARGET" && exit 10
      ;;
    esac
    health_check
    echo "Deploy completed."
}

main "$@"