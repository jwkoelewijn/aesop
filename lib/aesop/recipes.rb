module Aesop
  module Capistrano
    def self.load_into(configuration)
      configuration.load do
        after "deploy:finalize_update", "aesop:record_deployment"
        namespace :aesop do
          desc "Record the current time into a file called DEPLOY_TIME"
          task :record_deployment, :roles => :app do
            set :deployment_time, Time.now.to_i.to_s
            put fetch(:deployment_time), "#{configuration.fetch(:release_path)}/DEPLOY_TIME"
          end
        end
      end
    end
  end
end

if cap_config = Capistrano::Configuration.instance
  Aesop::Capistrano.load_into(cap_config)
end
