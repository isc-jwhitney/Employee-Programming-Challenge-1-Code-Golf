cd "$(dirname $0)"

for i in $(seq 1 ${1:-99999}); do
	./reset-environment.sh >/dev/null 2>&1
	./test-warm-start.sh 1 | grep 'Elapsed time'
done
