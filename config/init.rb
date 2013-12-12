require 'configatron'

configatron.redis do |redis|
  redis.host = 'localhost'
  redis.port = 6379
  redis.password = ''
  redis.database = 1
end

configatron.logger do |logger|
  logger.name = 'Aesop'
  logger.level = Aesop::Logger::INFO
  logger.outputters = 'stdout'
end

configatron.deployment_key   = 'aesop:deployment:timestamp'
configatron.deployment_file  = 'DEPLOY_TIME'
configatron.exception_prefix = 'aesop:exceptions'
configatron.exception_count_threshold = 10
configatron.exception_time_threshold  = 60*60

configatron.phonenumbers = []
configatron.dispatchers  = [:log_dispatcher]
configatron.excluded_exceptions = []
