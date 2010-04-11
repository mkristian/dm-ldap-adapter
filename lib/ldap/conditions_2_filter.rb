require 'net/ldap'

module Ldap
  class Conditions2Filter

    @@logger = ::Slf4r::LoggerFacade.new(::Ldap::Conditions2Filter)

    # @param Array of conditions for the search
    # @return Array of Hashes with a name/values pair for each attribute
    def self.convert(conditions)
      @@logger.debug { "conditions #{conditions.inspect}" }
      filters = []
      conditions.each do |cond|
        c = cond[2]
        case cond[0]
        when :or_operator
          f = nil
          cond[1].each do |cc|
            ff = case cc[0]
                 when :eql
                   Net::LDAP::Filter.eq( cc[1].to_s, cc[2].to_s )
                 when :gte
                   Net::LDAP::Filter.ge( cc[1].to_s, cc[2].to_s )
                 when :lte
                   Net::LDAP::Filter.le( cc[1].to_s, cc[2].to_s )
                 when :like
                   Net::LDAP::Filter.eq( cc[1].to_s, cc[2].to_s.gsub(/%/, "*").gsub(/_/, "*").gsub(/\*\*/, "*") )
                 else
                   logger.error(cc[0].to_s + " needs coding")
                 end
            if f
              f = f | ff
            else
              f = ff
            end
          end
        when :eql
          if c.nil?
            f = ~ Net::LDAP::Filter.pres( cond[1].to_s )
          elsif c.respond_to? :each
            f = nil
            c.each do |cc|
              if f
                f = f | Net::LDAP::Filter.eq( cond[1].to_s, cc.to_s )
              else
                f = Net::LDAP::Filter.eq( cond[1].to_s, cc.to_s )
              end
            end
            #elsif c.class == Range
            #  p c
            #  f = Net::LDAP::Filter.ge( cond[1].to_s, c.begin.to_s ) & Net::LDAP::Filter.le( cond[1].to_s, c.end.to_s )
          else
            f = Net::LDAP::Filter.eq( cond[1].to_s, c.to_s )
          end
        when :gte
          f = Net::LDAP::Filter.ge( cond[1].to_s, c.to_s )
        when :lte
          f = Net::LDAP::Filter.le( cond[1].to_s, c.to_s )
        when :not
            if c.nil?
              f = Net::LDAP::Filter.pres( cond[1].to_s )
            elsif c.respond_to? :each
              f = nil
              c.each do |cc|
              if f
                f = f | Net::LDAP::Filter.eq( cond[1].to_s, cc.to_s )
              else
                f = Net::LDAP::Filter.eq( cond[1].to_s, cc.to_s )
              end
            end
              f = ~ f
            else
              f = ~ Net::LDAP::Filter.eq( cond[1].to_s, c.to_s )
            end
        when :like
          f = Net::LDAP::Filter.eq( cond[1].to_s, c.to_s.gsub(/%/, "*").gsub(/_/, "*").gsub(/\*\*/, "*") )
        else
          logger.error(cond[0].to_s + " needs coding")
        end
        filters << f if f
      end

      filter = nil
      filters.each do |f|
        if filter.nil?
          filter = f
        else
          filter = filter & f
        end
      end
      @@logger.debug { "search filter: (#{filter.to_s})" }
      filter
    end
  end
end
