# Vargant for Dogs - Opcache for php

Caching opcode (storing precompiled script)

## Installation

* Ajouter "vagrant/opcache/provisioner.sh" dans la propriété "provision" du fichier vagrant.json
Comment the parameter named : opcache.validate_timestamps for production

All parameters:
opcache.revalidate_freq=0 #How often in second the cache will be refresh
opcache.validate_timestamps=0 #Will check the file timestamp per your opcache.revalidate_freq value (if disable, revalidate_freq param is ignored and files are never checked.
opcache.max_accelerated_files=4000 #How many files can be manage (use find . -type f -print | grep php | wc -l to count the number)
opcache.memory_consumption=192 #Memory available
opcache.interned_strings_buffer=16 #Store 1 immutable variable for same string found
opcache.fast_shutdown=1 #Speed up the response

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
