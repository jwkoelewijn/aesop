class Aesop::Dispatchers::LogDispatcher
  include ::Aesop

  def dispatch_exception(exception)
    Aesop::Logger.info( exception.class.to_s )
  end
end
