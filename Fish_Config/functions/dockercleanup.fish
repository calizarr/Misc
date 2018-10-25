function dockercleanup
    docker ps -q --filter "status=exited" | xargs docker rm; and docker images -q --filter "dangling=true" | xargs docker rmi
end