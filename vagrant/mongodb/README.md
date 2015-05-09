# Vargant for Dogs

## Mongodb

#### Introduction

Mongodb is a nosql storage system

#### Installation

* Ajouter "vagrant/mongodb/mailcatcher.sh" dans la propriété "provision" du fichier vagrant.json

```json
"provision": [
    "vagrant/VagrantEmulsion.sh",
    "vagrant/mongodb/provisioner.sh"
]
```

* Provisionner la vagrant

```bash
vagrant up
-- ou --
vagrant provision
```
