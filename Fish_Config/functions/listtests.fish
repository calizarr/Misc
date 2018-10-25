function listtests
   echo "sbt 'show test:definedTestNames'"
   sbt 'show test:definedTestNames'
end