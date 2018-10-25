function ghp  
    set repo (git rev-parse --show-toplevel | xargs basename)
    open https://www.github.com/cibotech/$repo/pulls
end