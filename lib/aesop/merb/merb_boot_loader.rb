module Aesop
  class MerbBootLoader < Merb::BootLoader
    after Merb::BootLoader::ChooseAdapter
    def self.run
      Aesop::Aesop.instance.init
    end
  end
end
