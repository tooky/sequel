require 'openbase'

module Sequel
  module OpenBase
    class Database < Sequel::Database
      set_adapter_scheme :openbase
      
      def connect(server)
        opts = server_opts(server)
        OpenBase.new(
          opts[:database],
          opts[:host] || 'localhost',
          opts[:user],
          opts[:password]
        )
      end
      
      def dataset(opts = nil)
        OpenBase::Dataset.new(self, opts)
      end
    
      def execute(sql, opts={})
        log_info(sql)
        synchronize(opts[:server]) do |conn|
          r = conn.execute(sql)
          yield(r) if block_given?
          r
        end
      end
      alias_method :do, :execute

      private

      def disconnect_connection(c)
        c.disconnect
      end
    end
    
    class Dataset < Sequel::Dataset
      SELECT_CLAUSE_ORDER = %w'distinct columns from join where group having compounds order limit'.freeze
      
      def fetch_rows(sql)
        execute(sql) do |result|
          begin
            @columns = result.column_infos.map{|c| output_identifier(c.name)}
            result.each do |r|
              row = {}
              r.each_with_index {|v, i| row[@columns[i]] = v}
              yield row
            end
          ensure
            # result.close
          end
        end
        self
      end
      
      private
      
      def select_clause_order
        SELECT_CLAUSE_ORDER
      end
    end
  end
end
