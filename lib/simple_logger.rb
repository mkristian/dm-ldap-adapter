require 'logger.rb'

module Ldap
  class LoggerFacade
   
    def initialize(name)
      @name = name
      @logger = ::Logger.new(STDERR)
      @logger.level = log_level
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    end

    def log_level
      ::Logger::INFO
    end

    private

    def log(type, msg, exception = nil)
      @logger.add(type, msg, @name)
      @logger.add(type, "#{exception.message}\n\t#{exception.backtrace.join('\n\t')}", @name) if exception
    end

    public 

    def debug?
      @logger.debug?
    end

    def debug(msg, exception = nil)
      log(::Logger::DEBUG, msg, exception)
    end

    def info?
      @logger.info?
    end

    def info(msg, exception = nil)
      log(::Logger::INFO, msg, exception)
    end

    def warn?
      @logger.warn?
    end

    def warn(msg, exception = nil)
      log(::Logger::WARN, msg, exception)
    end

    def error?
      @logger.error?
    end

    def error(msg, exception = nil)
      log(::Logger::ERROR, msg, exception)
    end

    def fatal?
      @logger.fatal?
    end

    def fatal(msg, exception = nil)
      log(::Logger::FATAL, msg, exception)
    end

  end
end
