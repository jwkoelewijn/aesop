require 'log4r'

module Aesop
  module Logger
    DEBUG  = 1
    INFO   = 2
    WARN   = 3
    ERROR  = 4
    FATAL  = 5

    class << self

      DEFAULT_OUTPUT = 'stdout'

      def log
        @logger ||= setup
      end

      def setup
        logger = Log4r::Logger.new(configuration.name)
        logger.level = configuration.level
        logger.outputters = configuration.outputters
        logger
      end

      def reset
        @logger = nil
      end

      # makes this respond like a Log4r::Logger
      def method_missing(sym, *args, &block)
        log.send sym, *args, &block
      end

      def configuration
        configatron.logger
      end

    end
  end
end
