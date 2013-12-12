module Aesop
  module Version
    MAJOR = 1
    MINOR = 0
    PATCH = 0
    BUILD = 1
  end

  VERSION = [Version::MAJOR, Version::MINOR, Version::PATCH, Version::BUILD].compact.join('.')
end
