function travis
    switch $argv[1]
    case help
        /usr/local/bin/travis $argv
    case '*'
        /usr/local/bin/travis $argv --pro
    end
end