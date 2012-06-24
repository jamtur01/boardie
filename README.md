Boardie
=======

Author
------

James Turnbull <james@lovedthanlost.net>

Prerequistes
------------

* Sintra
* Datamapper
* Sqlite3

Installation
------------

    $ sudo gem install boardie

Usage
-----

Usage: boardie [options] ...

Common options:
    -v, --version                    Display version
    -h, --help                       Display this screen

The configuration file, `config/config.yml` should contain
values for:

    redmine_site: 'https://support.example.com'
    redmine_key: abcde12334
    redmine_project: example_project
    inprogress_quota: 6

The `inprogress_quota` indicates the max number of issues that can be in progress at a time.

An example file is in the `config` directory.

License
-------

See LICENSE file.

