function gitcleanb
    git b | grep -v master | grep -v "\*" | xargs git b -d $argv
end