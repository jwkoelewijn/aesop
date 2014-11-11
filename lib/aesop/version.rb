module Aesop
  module Version
    MAJOR = 1
    MINOR = 1
    PATCH = 0
    BUILD = 3
  end

  VERSION = [Version::MAJOR, Version::MINOR, Version::PATCH, Version::BUILD].compact.join('.')
end
