module QuotaValidation
  def self.included(base)
    base.extend ClassMethods
  end
  module ClassMethods
    def validates_quota_of(column, key, options={})
      options = options.dup
      scope = options.delete(:scope)
      max   = QuotaValidation.lookup_setting(self,key)

      message = (options[:message] || ActiveRecord::Errors.default_error_messages[:less_than_or_equal_to]) % max

      validates_each(column, options) do |record, column, value|
        finder_opt = scope ? {:conditions => {scope => record.send(scope) }} : {}
        if(sum(column, finder_opt) + value) > max
          record.errors.add(column, message)
        end
      end
    end
  end


  def lookup_setting(klass, key)
    if SkipEmbedded::InitialSettings['wiki'] and SkipEmbedded::InitialSettings['wiki']['quota']
      SkipEmbedded::InitialSettings['wiki']['quota'][klass.name.underscore][key.to_s]
    else
      nil
    end
  end
  module_function :lookup_setting
end

