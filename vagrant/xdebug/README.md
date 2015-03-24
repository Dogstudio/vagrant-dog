# Vagrant for Dogs

## Xdebug

#### Installation

* Ajouter "vagrant/xdebug/provisioner.sh" dans la propriété "provision" du fichier vagrant.json

```json
"provision": [
    "vagrant/VagrantEmulsion.sh",
    "vagrant/xdebug/provisioner.sh"
]
```

* Provisionner la vagrant

```bash
vagrant up
-- ou --
vagrant provision
```

#### Phpstorm

* Installer la bookmarklet phpstorm dans votre navigateur
* Activer le bouton 'listen to xdebug connections' dans phpstorm
* Activer l'options 'start debugger' de la bookmarklet de la page que vous voulez debugger
* Mettre un breakpoint dans votre code
* reloader la page
* Debugger
