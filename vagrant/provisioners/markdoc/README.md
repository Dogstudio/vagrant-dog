# Markdown Doc & Directory Index

Améliore l'affichage des répertoires et permet de "parser" les fichiers _markdown_.

## Installation

* Ajouter "vagrant/markdoc/provisioner.sh" dans la propriété "provision" du fichier vagrant.json

```json
"provision": [
    "vagrant/provisioners/vagrantdog/provisioner.sh",
    "vagrant/provisioners/markdoc/provisioner.sh"
]
```

## Utilisation 

Placer la documentation du projet dans le répertoire `/doc` et afficher son contenu via le navigateur : `http://votreprojet.dev/doc`