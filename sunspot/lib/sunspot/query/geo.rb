begin
  require 'geohash'
rescue LoadError => e
  require 'pr_geohash'
end

module Sunspot
  module Query
    class Geo
      MAX_PRECISION = 12
      DEFAULT_PRECISION = 7
      DEFAULT_PRECISION_FACTOR = 16.0

      def initialize(field, lat, lng, options)
        @field, @options = field, options
        @geohash = GeoHash.encode(lat.to_f, lng.to_f, max_precision)
      end

      def to_params
        { :q => to_boolean_query }
      end

      def to_subquery
        "(#{to_boolean_query})"
      end

      private

      def to_boolean_query
        queries = []
        max_precision.downto(precision) do |i|
          star = i == MAX_PRECISION ? '' : '*'
          precision_boost = Util.format_float(
            boost * precision_factor ** (i-max_precision).to_f, 3)
          queries << "#{@field.indexed_name}:#{@geohash[0, i]}#{star}^#{precision_boost}"
        end
        queries.join(' OR ')
      end

      def max_precision
        @options[:max_precision] || MAX_PRECISION
      end

      def precision
        @options[:precision] || DEFAULT_PRECISION
      end

      def precision_factor
        @options[:precision_factor] || DEFAULT_PRECISION_FACTOR
      end

      def boost
        @options[:boost] || 1.0
      end
    end
  end
end
