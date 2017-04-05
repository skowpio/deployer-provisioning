# deployer-provisioning
All stuff responsible for deployer provisioning should go here. 

## Playbook prupose
Provision up and running two putit services: putit-core and putit-auth 

Playbook has been tested on Centos 7 x64 

## How to use it
1. Install clean version of Centos 7 with basic packages. 

2. Create account which password less access to sudo. 

3. Install ansible on your work station. 

4. Make sure you can connect to fresh CentOS instance from your work station via SSH using account created in step 2. 
TIP: Use Virtual box NAT if neccessery and port forwarding 

5. Create on work station ~/.ssh/config 

```
host dev-deployer
    HostName localhost
    Port 2240
    User ACCOUNT_NAME_CREATED_IN_STEP_2
    IdentityFile ~/.ssh/PATH_TO_YOUR_PRIV_KEY
    ServerAliveInterval 10
   
```
Above its just example. Port or host could be different but please keep: dev-deployer in first line. Ansible will use that name. 

6. Clone this repository 

7. Ask for private key to access private repos
Save the key under path: 

```
files/ssh_prv_keys/depapp_rsa.prv
```

8. Run playbook
```
ansible-playbook -i inventory-dev-deployer dev-deployer.yml  -b -v
```
