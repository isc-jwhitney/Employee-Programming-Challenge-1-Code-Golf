docker-compose exec iris bash -c "for file in /home/irisowner/dev/data/out/*; do echo --- \$(basename \$file) ---; cat \$file; echo -e '\n' ; done"
