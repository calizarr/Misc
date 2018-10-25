function tardir
    echo "   tar -zcvf archive-name.tar.gz directory-name"
    echo "   tardir archive-name.tar.gz directory-name"
    tar -zcvf $argv
end