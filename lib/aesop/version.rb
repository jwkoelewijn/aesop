module Aesop
  module Version
    MAJOR = 1
    MINOR = 2
    PATCH = 0
    BUILD = 0
  end

  VERSION = [Version::MAJOR, Version::MINOR, Version::PATCH, Version::BUILD].compact.join('.')
end
