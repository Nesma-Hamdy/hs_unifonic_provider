module HsUnifonicProvider
  module MobileNumberNormalizer
    def self.normalize_number(number,path_from = '')

      if path_from.empty?
        n=number.dup
        while n.start_with?('+') || n.start_with?('0')
          n.slice!(0)
        end
        return n
      else
        return number.gsub(/[^a-z,0-9]/, "")
      end
    end

    def self.normalize_message(message)
      message.encode(Encoding::UTF_8)
    end
  end
end
