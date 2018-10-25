function prod
    switch $argv[1]
    case docker
    	echo "docker exec -it $argv[2] bash"
        docker exec -it $2 bash
    case '*'
    	echo "ssh bpuntin@$argv[1].ops.cibotechnologies.com"
    	ssh bpuntin@$argv[1].ops.cibotechnologies.com
    end
end