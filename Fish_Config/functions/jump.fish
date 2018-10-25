function jump
	echo "ssh ec2-user@$argv" | pbcopy
    ssh-add ~/.ssh/devops-id_rsa
    ssh -A bpuntin@prod-devops2.ops.cibotechnologies.com
end