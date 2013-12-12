module Aesop
  module Rails
    class Middleware
      def initialize( app )
        @app = app
      end

      def call( env )
        begin
          response = @app.call(env)
        rescue Exception => e
          Aesop::Aesop.instance.catch_exception(e)
        end
        response
      end
    end
  end
end
