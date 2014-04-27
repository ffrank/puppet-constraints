module Puppet
  newtype(:constraint) do

    newparam(:resource) do
      desc "A reference to the resource that is being constrained."

      # TODO validation

      # TODO support for Type[name1,name2,...] and general arrays (munge?)
    end

    newparam(:properties) do
      desc "A hash of hashes. Keys in the first layer are property names. 
      Possible keys in the second layer are: forbidden, allowed.
      
      Examples:
      
          { ensure => { allowed => [ present, latest, installed ] } }
      
          { ensure => { forbidden => [ purged, absent ] } }"

      validate do |value|
        fail "properties must be a hash" unless value.is_a?(Hash)

	# TODO: check the structure and content of the hash
      end

      munge do |value|
        result = {}
        value.each_pair do |prop,propval|
          if [ String, Array ].include? propval.class
            # allow strings and arrays, defaulting to allow list
            result[prop] = { :allowed => [ propval ].flatten }
          else
            # encapsulate allowed/forbidden values in arrays if necessary
            result[prop] = { propval.keys[0] => [ propval.values[0] ].flatten }
          end
        end
        recursive_intern(result)
      end

      def recursive_intern(value)
        case value
        when String
          return value.intern
        when Array
          return value.map { |v| recursive_intern v }
        when Hash
          result = {}
          value.keys.each do |k|
            result[k.intern] = recursive_intern(value[k])
          end
          return result
        else
          devfail "constraint trying to intern #{value.inspect} of type #{value.class}"
        end
      end

      defaultto do
        {}
      end

    end

    newparam(:name) do
      desc "The constraint's name."

      isnamevar
    end

    def in_valid_catalog?
      resource = self.catalog.resource(self[:resource].to_s)
      raise "the resource #{self[:resource]} cannot be found in the catalog" unless resource

      Puppet.debug "Checking constraint on #{self[:resource]} #{self[:properties].inspect}"

      self[:properties].each_pair do |property,constraint|
        constraint.each_pair do |constraint_type,constraint_values|
          case constraint_type
          when :allowed
            next if constraint_values.include?(resource[property])
            return constraint_fail "#{resource.ref}/#{property} is '#{resource[property]}' which is not among the allowed [#{ constraint_values * ','}]"
          when :forbidden
            next unless constraint_values.include?(resource[property])
            return constraint_fail "#{resource.ref}/#{property} is '#{resource[property]}' which is forbidden"
          end
        end
      end
      true
    end

    def constraint_fail(msg)
      Puppet.err "constraint #{self.ref} check failed - #{msg}"
      # always return false - this will be the return value of in_valid_catalog?
      false
    end

    @doc = "Constraints allow modules to express dependencies on resources 
      that are managed by other parts of the manifest, most likely
      other modules.
      
      They are an alternative to the ensure_resource function from stdlib
      as well as the common workaround of declaring shared resources inside
      `if !defined(Ref[resource])` blocks.
      
      As any resource, each constraint must have a unique title, but each
      concrete resource can be targeted by multiple constraints without issue.
      Each attribute of the target resource can be limited to a list of allowed
      values, or a list of values can be forbidden for each attribute.

      Mutually exclusive constraints are not checked for, but a catalog that
      contains them cannot ever pass the constraint check, because at least
      one of them will fail."
  end
end
