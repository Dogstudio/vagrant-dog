# Vargant for Dogs

## Nodejs

#### Introduction

Nodejs installation

#### Installation

* Ajouter "vagrant/nodejs/provisioner.sh" dans la propriété "provision" du fichier vagrant.json

```json
"provision": [
    "vagrant/VagrantEmulsion.sh",
    "vagrant/nodejs/provisioner.sh"
]
```

* Provisionner la vagrant

```bash
vagrant up
-- ou --
vagrant provision
```
