# ssh-config

Script for showing [ssh_config(5)](http://linux.die.net/man/5/ssh_config) for a given host.

## Usage

- symlink or copy the script somewhere in the $PATH
- add bash completion for ssh-config `complete -F _ssh ssh-config`
- reload shell
- use as `ssh-config hostname`

## Stollen from 
Parsing logic stollen from `net-ssh` gem, [Net::SSH::Config](https://github.com/net-ssh/net-ssh/blob/master/lib/net/ssh/config.rb) class.
