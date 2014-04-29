puppet-constraints
==================

[![Build Status](https://travis-ci.org/ffrank/puppet-constraints.png)](https://travis-ci.org/ffrank/puppet-constraints)

Puppet module that introduces the constraint type.

Origin: https://github.com/ffrank/puppet-constraints

Released under the terms of the Apache 2 License.

This module has passed basic testing with all Puppet versions since 2.6.0.

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
      'foo': resource   => Package['apache2'],
             properties => { ensure => present };
      'bar': resource   => Package['apache2'],
             properties => { ensure => [ present ] };
      'baz': resource   => Package['apache2'],
             properties => { ensure => { allowed => [ present ] } };
    }
    # Blacklist instead of whitelist
    constraint {
      'oof': resource   => Package['apache2'],
             properties => { ensure => { forbid => [ absent, purged ] } };
    }

Any failed constraint causes the catalog to be considered invalid (agent side).
