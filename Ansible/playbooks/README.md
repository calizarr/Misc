# Playbooks Folder #

## Setting up a VM such as Ubuntu etc. ##
Example command for the named playbook below.
- `ansible-playbook -i ~/.ansible/hosts.yaml ubuntu-20.04_vm_setup_roles.yaml -e "git_user=FIRST_NAME LAST_NAME'" -e "git_email=EMAIL" -e "scale_4k=true" -e "remote_usr=$USER'" -e "host=$VM_NAME" --ask-vault-pass -e @secret_key -vv`

## VM Resources for Desktop
- HDD: 250 GB
- CPU: 4
- RAM: 8192 KB (8 GB)
- GPU RAM: 1 GB
