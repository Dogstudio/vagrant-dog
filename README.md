# Vargant for Dogs

_Vagrantfile_ et _Boxes_ pour le développement des projets. 

## Utilisation

> Il suffit de copier les fichiers et de modifier la configuration JSON.

Comme on a pas besoin du versionning de ce projet, on commence par exporter les fichiers à la racine de notre projet. 
  
    git archive --remote git@gitlab.dogstudio.be:devtools/vagrantdog.git master | tar -x -C ./

Dans le répertoire `vagrant`, on adapte les paramètres du fichier `sample.json` (voir plus bas pour les détails).

    vim vagrant/sample.json

Ensuite, on effectue une copie du fichier à la racine en le renommant `vagrant.json`.

    cp vagrant/sample.json vagrant.json

Ce nouveau fichier **ne doit pas être inclus dans le dépôt** de notre projet ; il est propre à chaque DEV.

Une fois les sources du projet installées, il ne reste plus qu'à démarrer la VM:

    vagrant up

## Vagrant.JSON

Le fichier JSON permet de fournir les paramètres spécifiques à la VM:

* `box_name` : nom de la BOX vagrant (option, default: "laravel/homestead")
* `box_url` : permet de télécharger la BOX, si pas déjà présente sur le système (option)
* `name` : nom du projet
* `host` : nom de l'hôte pour tester l'application
* `path` : chemin vers la racine du site (option, default: "/vagrant/public")
* `private_ip` : adresse IP privée **Obligatoire**
* `public_ip` : adresse IP public (accessible depuis l'extérieur).
* `provision` : **tableau** reprenant les chemins des scripts (SH) de provisioning.

### PublicIP 

Pour l'adresse IP publique, il est possible de spécifier un entier, ex: 123 (au lieu d'une IP).

Dans ce cas, le script détectera l'adresse IP de l'hôte et utilisera l'entier pour générer l'adresse publique dans le même range que l'hôte. 
C'est particulièrement utile dans le cas des laptops qui change de range réseau et de bridge suivant l'endroit de connexion.

_Ex:_ 

* `public_ip` : 200
* Détection de l'inteface de l'hôte : `en0: Wifi Airport`
* Détection de l'adresse de l'hôte : `10.0.0.45`
* Générer l'adresse : `10.0.0.200`

## Alias

Pour faciliter l'utilisation, on peut ajouter les commandes Vagrant au `.bashrc` (ou `.bash_aliases`)

```bash
echo "#Vagrant
alias vup='vagrant up'
alias vhalt='vagrant halt'
alias vdestroy='vagrant destroy'
alias vrestart='vhalt && vup'
alias vssh='vagrant ssh'
alias vstate='vagrant global-status'" >> ~/.bashrc
```

