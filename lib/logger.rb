require 'logging'

module Ldap
  class LoggerFacade

    attr_reader :logger

    def initialize(name)
      log_name = nil
      name.to_s.split("::").each do |n|
        if log_name
          log_name += "::#{n}"
        else
          log_name = n
        end
        @logger = ::Logging::Logger.new(log_name)
      end
    end

    private

    def log(type, msg = nil, exception = nil)
      @logger.add(type, msg) if msg
      @logger.add(type, exception) if exception
    end

    public 

    def debug?
      @logger.level == 0
    end

    def debug(msg, exception = nil)
      log(0, msg, exception)
    end

    def info?
      @logger.level <= 1
    end

    def info(msg, exception = nil)
      log(1, msg, exception)
    end

    def warn?
      @logger.level <= 2
    end

    def warn(msg, exception = nil)
      log(2, msg, exception)
    end

    def error?
      @logger.level <= 3
    end

    def error(msg, exception = nil)
      log(3, msg, exception)
    end

    def fatal?
      @logger.level <= 4
    end

    def fatal(msg, exception = nil)
      log(4, msg, exception)
    end

  end
end
