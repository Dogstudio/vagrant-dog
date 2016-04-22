# Vagrant for Dogs

_Vagrantfile_ and _Boxes_ for Dogstudio projects.

## Usage

> You must copy the source files and edit the JSON configuration.

So, because we don't need to keep this project in GIT, we start to export source files in the project root folder.

    git archive --remote #GIT_URL#/vagrantdog.git master | tar -x -C ./

In the `vagrant`folder, we edit the configuration file `sample.json` (see below for details).

    vim vagrant/sample.json

After that, we make a copy of this file in the root folder and rename it as `vagrant.json`.

    cp vagrant/sample.json vagrant.json

This new file is your personal environnement and don't need to put un the new repo.
Put your project source in `dev` folder (`dev/public` is the web root) and state the VM:

    vagrant up

## Vagrant.JSON

This JSON file provide specific parameters for your virtual machine :

* `box_name` : the vagrant BOX name you use. (optional, default: "VagrantDog")
* `box_url` : the URL to download the BOX (for the first time). (optional)
* `name` : the name of your project
* `host` : the host name to test your project
* `path` : the path to the web root (option, default: "/dev/public/")
* `private_ip` : a private IP address (**mandatory**)
* `public_ip` : a public IP address (to test your project with external device).
* `provision` : **array** with provisioning script paths (.sh).

## database/dump.sql

If you have file named `database/dump.sql`, it will be automaticly injected in the database
when you provision your virtual machine for the 1st time.

### PublicIP

To provide public IP, you can specify an **interger** instead of a IP. (ex: 123).

In this case, the provisoner script will detect the host IP and use it to generate an adresse in the same range with the integer for the last part.
It's very usefull when your are mobile and your IP range change according your location.

_For example:_

* `public_ip` : 200
* Detection of your host main network interface: `en0: Wifi Airport`
* Detection of the host IP address: `10.0.0.45`
* Generate your VM public IP  : `10.0.0.200`

## Additional provisioners

You can find some additional provisioners in `vagrant/provisioners`.  
Example : `vagrant/provisioners/mailcatcher/provisioner.sh

For each one, the provisoner folder must contains at least:

* A `provisioner.sh` file
* A `README.md` file that explain what that provisioner do.

To use this provisionaer, you just need to add his path in the `provision` array of `vagrant.json`

```json
"provision": [
    "vagrant/provisioners/vagrantdog/provisioner.sh",
    "vagrant/provisioners/mailcatcher/provisioner.sh"
]
```


