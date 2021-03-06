module Errplane
  class Configuration
    attr_accessor :api_key
    attr_accessor :api_host
    attr_accessor :api_host_port
    attr_accessor :app_host
    attr_accessor :application_id
    attr_accessor :application_name
    attr_accessor :application_root

    attr_accessor :logger
    attr_accessor :environment
    attr_accessor :framework
    attr_accessor :framework_version
    attr_accessor :language
    attr_accessor :language_version
    attr_accessor :ignored_exceptions
    attr_accessor :ignored_exception_messages
    attr_accessor :ignored_reports
    attr_accessor :ignored_environments
    attr_accessor :ignored_user_agents
    attr_accessor :backtrace_filters
    attr_accessor :aggregated_exception_classes
    attr_accessor :environment_variables
    attr_accessor :environment_variable_filters

    attr_accessor :instrumentation_enabled
    attr_accessor :debug
    attr_accessor :reraise_global_exceptions

    attr_accessor :queue_worker_threads
    attr_accessor :queue_worker_polling_interval
    attr_accessor :queue_maximum_depth
    attr_accessor :queue_maximum_post

    DEFAULTS = {
      :api_host => "apiv2.errplane.com",
      :app_host => "app.errplane.com",
      :ignored_exceptions => %w{ActiveRecord::RecordNotFound
                              ActionController::RoutingError},
      :ignored_exception_messages => [],
      :ignored_reports => [],
      :ignored_environments => %w{test cucumber selenium},
      :ignored_user_agents => %w{GoogleBot},
      :environment_variable_filters => [
        /password/i,
        /key/i,
        /secret/i
      ],
      :backtrace_filters => [
        lambda { |line| line.gsub(/^\.\//, "") },
        lambda { |line|
          return line if Errplane.configuration.application_root.to_s.empty?
          line.gsub(/#{Errplane.configuration.application_root}/, "[APP_ROOT]")
        },
        lambda { |line|
          if defined?(Gem) && !Gem.path.nil? && !Gem.path.empty?
            Gem.path.each { |path| line = line.gsub(/#{path}/, "[GEM_ROOT]") }
          end
          line
        }
      ]
    }

    def initialize
      @api_host = DEFAULTS[:api_host]
      @api_host_port = DEFAULTS[:api_host_port]
      @app_host = DEFAULTS[:app_host]
      @ignored_exceptions = DEFAULTS[:ignored_exceptions].dup
      @ignored_exception_messages = DEFAULTS[:ignored_exception_messages].dup
      @ignored_reports = DEFAULTS[:ignored_reports].dup
      @ignored_environments = DEFAULTS[:ignored_environments].dup
      @ignored_user_agents = DEFAULTS[:ignored_user_agents].dup
      @backtrace_filters = DEFAULTS[:backtrace_filters].dup
      @environment_variable_filters = DEFAULTS[:environment_variable_filters]
      @aggregated_exception_classes = []
      @debug = false
      @rescue_global_exceptions = false
      @instrumentation_enabled = true
      @queue_worker_threads = 3
      @queue_worker_polling_interval = 5
      @queue_maximum_depth = 10_000
      @queue_maximum_post = 500
    end

    def debug?
      !!@debug
    end

    def instrumentation_enabled?
      !!@instrumentation_enabled
    end

    def reraise_global_exceptions?
      !!@reraise_global_exceptions
    end

    def ignore_user_agent?(incoming_user_agent)
      return false if self.ignored_user_agents.nil?
      self.ignored_user_agents.any? {|agent| incoming_user_agent =~ /#{agent}/}
    end

    def ignore_current_environment?
      self.ignored_environments.include?(self.environment)
    end

    def define_custom_exception_data(&block)
      @custom_exception_data_handler = block
    end

    def add_custom_exception_data(black_box)
      @custom_exception_data_handler.call(black_box) if @custom_exception_data_handler
    end

    private
    def initialize_http_connection
      Net::HTTP.new(@app_host, "80")
    end
  end
end
