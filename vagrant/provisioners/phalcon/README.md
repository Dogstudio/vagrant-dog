# Vagrant for Dogs

## CPhalcon framework

#### Introduction

This provisioner install Phalcon php framework as c-extension for you!

#### Installation

* Simply add the provisioner to your vagrant.json : "vagrant/phalcon/provisioner.sh"

```json
"provision": [
    "vagrant/VagrantEmulsion.sh",
    "vagrant/phalcon/provisioner.sh"
]
```

Simply perform the usual command to wake up your vagrant and voilà !

```bash
vagrant up
-- or --
vagrant provision
```
