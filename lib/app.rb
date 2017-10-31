require 'sinatra'

class CassandraExampleApp < Sinatra::Base
  before do
    content_type "text/plain"

    if cassandra_service_not_bound_to_app?
      halt(500, bind_cassandra_service_to_app_instructions)
    end
  end

  error do |exception|
    halt(500, exception.message)
  end

  post '/:table_name' do
    cassandra_client.create_table(params[:table_name])
  end

  delete '/:table_name' do
    cassandra_client.drop_table(params[:table_name])
  end

  private

  def bind_cassandra_service_to_app_instructions
    %{
      You must bind a Cassandra service instance to this application.

      You can run the following commands to create an instance and bind to it:

        $ cf create-service p-dse-cassandra single-node cassandra-instance
        $ cf bind-service cassandra-example-app cassandra-instance
    }
  end

  def cassandra_client
    @cassandra_client ||= begin
      require 'cassandra_client'
      CassandraClient.new(connection_details: cassandra_connection_details)
    end
  end

  def cassandra_connection_details
    @cassandra_connection_details ||= begin
      require "cf-app-utils"
      CF::App::Credentials.find_all_by_all_service_tags(%w[cassandra]).first
    end
  end

  def cassandra_service_not_bound_to_app?
    !cassandra_connection_details
  end
end
