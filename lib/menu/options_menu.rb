class OptionsMenu

  def self.registered_handlers
    @registered_handlers ||= {}
  end

  def self.register(handler)
    OptionsMenu.registered_handlers[handler] = self
  end

end
