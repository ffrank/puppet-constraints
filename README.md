#puppet-constraints

[![Build Status](https://travis-ci.org/ffrank/puppet-constraints.png)](https://travis-ci.org/ffrank/puppet-constraints)

Puppet module that introduces the constraint type.

Origin: https://github.com/ffrank/puppet-constraints

Released under the terms of the Apache 2 License.

This module has passed basic testing with all Puppet versions since 2.6.0.

Authored by Felix Frank.

##Overview

This module implements `constraints`, a new meta type that aims
to make both the `ensure_resources` function and the `defined` function obsolete.
More information can be found in John Bollinger's
[original mailing list post](https://groups.google.com/d/msg/puppet-users/Fvl0aOe4RPE/Ph38bq3FmHcJ)
which explains their motivation, lays out their semantics and sketches their syntax.

##Usage

Use constraints in modules that depend on some resources to be managed in a
specific way, but that do not own such resources (e.g. software packages that
belong to a dedicated module).

A constraint defines what values are allowed (or expressly forbidden) for any
desired subset of properties of a (group of) resource(s). Those rules
are checked before the catalog is applied. 

Any failed constraint causes the catalog to be considered invalid (agent side).

###Syntax Overview

There are currently two ways to declare constraints.

 - with a hash of properties
```puppet
constraint {
  'foo': resource   => Package['apache2'],
         properties => { ensure => { allowed => [ present ] } };
  'bar': resource   => Package['apache2'],
         properties => { ensure => { forbidden => [ purged, absent ] } };
}
```
  (a whitelist and a blacklist respectively)
 - with separate hashes for blacklists and whitelists
```puppet
constraint {
  'foo': resource   => Package['apache2'],
         allow => { ensure => [ present ] };
  'bar': resource   => Package['apache2'],
         forbid => { ensure => [ purged, absent ] };
}
```

**Note:** Single element list can be shortened to a string.
```puppet
constraint {
  'foo': resource   => Package['apache2'],
         properties => { ensure => { allowed => present } };
}
```

**Note:** With the `properties` syntax, whitelists can be further simplified
by skipping the `allowed` key (it is implied then)
```puppet
constraint {
  'foo': resource   => Package['apache2'],
         properties => { allowed => present };
}
```

###Available parameters

####resource

A resource reference, such as you would use with relationship metaparameters
like `before` or `notify`.

**Example**

    resource => [ Package["apache2"], File["/etc/apache2","/var/www"] ]

####properties

Composite parameter to specify all constraint values for all target properties.
The value must be a nested hash with the following structure:

    { property_name => {
        value_type => {
          value_list
        }
      },
      ...
    }

where
 - `property_name` is just a name of a resource property such as `ensure`, `enable`, `command` ...
 - `value_type` is either `allowed` or `forbidden`, resulting in a whitelist or blacklist respectively
 - `value_list` is a single value or an array of such values, e.g. `present` or `[ 'installed', 'latest' ]`
There can be an arbitrary number of properties, but only one `value_type` per property
(whitelist or blacklist, as a mixture does not make sense).

The constraint values apply to the named properties of each [target resource](#resource).

The `properties` parameter is incompatible with both the `allow` and `forbid` parameters.

####allow

Declare whitelists of acceptable values for an arbitrary subset
of the [target resource's](#resource) properties.

The value must be a hash with the structure:

    { property_name => value_list, ... }

where `property_name` and `value_list` have the same semantics as described
for the [properties parameter](#properties).

####forbid

This parameter is similar to the [allow parameter](#allow), but instead of declaring
acceptable whitelists, it is about blacklists of values that the
[resource(s)](#resource) must not use.
