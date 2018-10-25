function runpostgres
	echo "executing: docker run --name agreliant-postgres -p5432:5432 -e POSTGRES_PASSWORD=agreliant -d postgres"
    docker run --name agreliant-postgres -p5432:5432 -e POSTGRES_PASSWORD=agreliant -d postgres
end