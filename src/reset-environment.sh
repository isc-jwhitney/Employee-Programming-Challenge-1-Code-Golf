cd "$(dirname $0)/.."

# Remove old output and temp files
docker-compose exec iris sh -c 'rm -rf /home/irisowner/dev/data/out/*; rm -rf /home/irisowner/dev/data/temp/*'

# Recreate the container
docker-compose kill
docker-compose rm -f
docker-compose up --build --force-recreate --always-recreate-deps -d

# Wait for the container to be ready to use
echo 'Wait for container to be healthy...'
while [ x"$(docker inspect --format='{{.State.Health.Status}}' $(docker-compose ps -q))" != x'healthy' ]; do sleep 1; done
