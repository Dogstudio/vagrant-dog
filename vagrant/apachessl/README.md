# Vargant for Dogs

## SSL mod for Apache2

#### Introduction

This provisioner enables the SSL support on your vagrant box. Enjoy !

#### Installation

* Simply add the provisioner to your vagrant.json : "vagrant/apachessl/provisioner.sh"

```json
"provision": [
    "vagrant/VagrantEmulsion.sh",
    "vagrant/mailcatcher/provisioner.sh"
]
```

Simply perform the usual command to wake up your vagrant and voilà !

```bash
vagrant up
-- or --
vagrant provision
```