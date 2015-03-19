# Vargant for Dogs

## Mailcatcher

#### Introduction

Mailcatcher est un serveur SMTP qui intercepte n'importe quel mail qui lui est envoyé et permet de consulter ces mails via une interface web

#### Installation

* Ajouter "vagrant/mailcatcher/provisioner.sh" dans la propriété "provision" du fichier vagrant.json

```json
"provision": [
    "vagrant/VagrantEmulsion.sh",
    "vagrant/mailcatcher/provisioner.sh"
]
```

* Provisionner la vagrant

```bash
vagrant up
-- ou --
vagrant provision
```
* Le client http sera disponible sur le port 1080. Il permet de consulter instantanément les mails envoyés depuis une application

#### Notes

* Le service est configuré pour intercepter les mails quelle que soit l'adresse ip de la vagrant.
* PHP : tous les envois de mail passant par la fonction PHP mail() seront interceptés automatiquement.
* Important : Les mails interceptés lors d'une session vagrant NE SONT PLUS disponibles lors de la session suivante
