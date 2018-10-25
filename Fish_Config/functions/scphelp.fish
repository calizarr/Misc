function scphelp
  echo "download: "
  echo "  scpdownload[r] {host} {remote-path}"
  echo "  scp bpuntin@{host}.ops.cibotechnologies.com:/tmp/chef-push.log  ./chef-push.log"
  echo "  use scpdownloadr for recursive download"
  echo "upload: "
  echo "  scpupload {local-files} {host} {remote-path}"
  echo "  scp ./chef-push.log brendonpuntin@{host}.ops.cibotechnologies.com:/tmp/chef-push.log"
end