module ThreadsafeAttr
  def threadsafe_attr_accessor(*attrs)
    attrs.each do |attr|
      reader attr
      writer attr
    end
  end

  private
  def reader(attr)
    define_method(attr) do
      Thread.current["#{self.name}.#{attr}"]
    end
  end

  def writer(attr)
    define_method("#{attr}=") do |value|
      Thread.current["#{self.name}.#{attr}"] = value
    end
  end
end
