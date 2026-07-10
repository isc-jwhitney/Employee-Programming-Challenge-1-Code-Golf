cd "$(dirname $0)/.."

# Remove old output and temp files
docker-compose exec iris sh -c 'rm -rf /home/irisowner/dev/data/out/*; rm -rf /home/irisowner/dev/data/temp/*'

# Import and compile src/RunScript.mac
docker-compose exec iris sh -c "(echo zw \\\$System.OBJ.Load\(\\\"/home/irisowner/dev/src/RunScript.mac\\\",\\\"ck\\\"\) ; echo h) | iris session iris" 2>&1 >/dev/null

# Run the test (hang 0.5 seconds in-between tests to give old processes time to finish, so they're less likely to affect the next run's timing)
for i in $(seq 1 ${1:-99999}); do
	docker-compose exec iris sh -c "(echo d ^RunScript h 0.5 ; echo h) | iris session iris" | grep 'Elapsed time'
done

