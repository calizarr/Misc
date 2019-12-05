#!/bin/bash

new=$(pwd)
old=$PYTHONPATH
printf '#!/bin/bash\nexport PYTHONPATH=%s\n' $old > revert.sh
PYTHONPATH=`printf '%s' "$(echo $PYTHONPATH | tr ':' '\n' | sed '/plantcv/d' | tr '\n' ':')"`$new
export PYTHONPATH=$PYTHONPATH
