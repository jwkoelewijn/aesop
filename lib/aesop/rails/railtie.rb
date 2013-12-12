module Aesop
  class Railtie < ::Rails::Railtie

    initializer "aesop.start_plugin" do |app|
      Aesop::Aesop.instance.init

      middleware = if defined?(ActionDispatch::DebugExceptions)
        # Rails >= 3.2.0
        "ActionDispatch::DebugExceptions"
      else
        # Rails < 3.2.0
        "ActionDispatch::ShowExceptions"
      end

      app.config.middleware.insert_after middleware, "Aesop::Rails::Middleware"
    end
  end
end
