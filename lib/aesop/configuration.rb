module Aesop
  def configuration
    configatron
  end

  def self.configuration
    if block_given?
      yield configatron
    else
      configatron
    end
  end
end
