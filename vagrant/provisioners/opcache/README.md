# Vargant for Dogs

## Opcache for php

#### Introduction

Caching opcode (storing precompiled script)

#### Installation

* Ajouter "vagrant/opcache/provisioner.sh" dans la propriété "provision" du fichier vagrant.json

```json
"provision": [
    "vagrant/VagrantEmulsion.sh",
    "vagrant/opcache/provisioner.sh"
]
```

* Provisionner la vagrant

```bash
vagrant up
-- ou --
vagrant provision
```
