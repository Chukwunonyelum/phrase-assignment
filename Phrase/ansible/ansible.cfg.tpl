[defaults]
inventory = inventory.ini
remote_user = ec2-user
private_key_file = ~/.ssh/my-key.pem
host_key_checking = False
retry_files_enabled = False

[ssh_connection]
ssh_args = -o ForwardAgent=yes -o ProxyCommand="ssh -i ~/.ssh/my-key.pem -W %h:%p ec2-user@${bastion_ip}"
