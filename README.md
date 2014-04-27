puppet-constraints
==================

Puppet module that introduces the constraint type.

Origin: https://github.com/ffrank/puppet-constraints

Released under the terms of the Apache 2 License.

This module requires Puppet to be patched in order to perform and respect
the checks of constraints. The patch is available in
[a topic branch](https://github.com/ffrank/puppet/tree/ticket/master/PUP-2298-transaction-pre-run-checks).

Authored by Felix Frank.

Overview
========

This module implements `constraints`, a new meta type that aims
to make both the `ensure_resources` function and the `defined` function obsolete.
More information can be found in John Bollinger's
[original mailing list post](https://groups.google.com/d/msg/puppet-users/Fvl0aOe4RPE/Ph38bq3FmHcJ)
which explains their motivation, lays out their semantics and sketches their syntax.

Currently, the following syntaxes are implemented:

    # These are all equivalent
    constraint {
      'foo': resource => Package['apache2'],
             { ensure => present };
      'bar': resource => Package['apache2'],
             { ensure => [ present ] };
      'baz': resource => Package['apache2'],
             { ensure => { allowed => [ present ] } };
    }
    # Blacklist instead of whitelist
    constraint {
      'oof': resource => Package['apache2'],
             { ensure => { forbid => [ absent, purged ] } };
    }

Any failed constraint causes the catalog to be considered invalid (agent side).
