module Timeliness
  module ThreadsafeAttr
    def threadsafe_attr_accessor(*attrs)
      attrs.each do |attr|
        storage_name = "#{name}.#{attr}".freeze
        reader attr, storage_name
        writer attr, storage_name
      end
    end

    private
    def reader(attr, storage_name)
      define_method(attr) do
        Thread.current[storage_name]
      end
    end

    def writer(attr, storage_name)
      define_method("#{attr}=") do |value|
        Thread.current[storage_name] = value
      end
    end
  end
end