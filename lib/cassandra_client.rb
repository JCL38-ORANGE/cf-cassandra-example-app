require 'cassandra'
require 'forwardable'

InvalidCassandraCredentialsException = Class.new(Exception)
CassandraUnavailableException = Class.new(Exception)
InvalidTableName = Class.new(Exception)
InvalidKeyspaceName = Class.new(Exception)
TableDoesNotExistException = Class.new(Exception)
KeyNotFoundException = Class.new(Exception)

class CassandraClient < SimpleDelegator
  def initialize(args)
    @connection_details = args.fetch(:connection_details)
    super(session)
  end

  def cluster
    @cluster = Cassandra.cluster(remapped_connection_details)
  end

  def connected?
    @session != nil
  end

  def session
    @session ||= cluster.connect

  rescue  Cassandra::Errors::AuthenticationError => exception
     raise(InvalidCassandraCredentialsException, exception)
  rescue Cassandra::Errors::NoHostsAvailable => exception
     raise(CassandraUnavailableException, exception)
  end


  def keyspace_exists?(keyspace_name)
    cluster.has_keyspace? keyspace_name
  end

  def table_exists?(keyspace_name, table_name)
    query = %{
      SELECT table_name
      FROM system_schema.tables
      WHERE keyspace_name=? AND table_name=?
    }

    prepared_statement = session.prepare(query)
    result = session.execute(prepared_statement, {arguments: [keyspace_name, table_name]})
    result.one?
  end

  def create_table(table_name)
    raise InvalidTableName if table_name.index(/[^0-9a-z_]/i)
    return if table_exists?(keyspace_name, table_name)
    query = %{
      CREATE TABLE "#{keyspace_name}"."#{table_name}" (
        id varchar PRIMARY KEY,
        value varchar
      )
    }
    session.execute(query)
  end

  def drop_table(table_name)
    raise InvalidTableName if table_name.index(/[^0-9a-z_]/i)
    return unless table_exists?(keyspace_name, table_name)
    query = %{
      DROP TABLE "#{keyspace_name}"."#{table_name}"
    }
    session.execute(query)
  end

  def store(args)
    #keyspace_name = args.fetch(:keyspace_name)
    table_name = args.fetch(:table_name)
    key = args.fetch(:key)
    value = args.fetch(:value)

    ensure_table_exists(keyspace_name, table_name)

    query = %{
      INSERT INTO "#{keyspace_name}"."#{table_name}" (id, value)
      VALUES (?, ?)
    }

    statement = session.prepare(query)
    session.execute(statement, {arguments: [key, value]})
  end

  def fetch(args)
    #keyspace_name = args.fetch(:keyspace_name)
    table_name = args.fetch(:table_name)
    key = args.fetch(:key)

    ensure_table_exists(keyspace_name, table_name)

    query = %{
      SELECT value
      FROM  "#{keyspace_name}"."#{table_name}"
      WHERE id=?
    }

    statement = session.prepare(query)
    result = session.execute(statement, {arguments: [key]})

    raise(KeyNotFoundException, %{"#{key}" key not found}) unless result.first

    result.first.fetch("value")
  end

  private

  attr_reader :connection_details

  def ensure_table_exists(keyspace_name, table_name)
    unless table_exists?(keyspace_name, table_name)
      raise(TableDoesNotExistException, %{Table "#{table_name}" does not exist})
    end
  end

  def keyspace_name
    #connection_details.fetch('keyspace_name')
    #connection_details.fetch('keyspace_name', "ks211af5f2_9fa8_40ae_a345_da5a109355c6")
    connection_details.fetch('keyspaceName')
  end

  def username
    #connection_details.fetch('username', "cassandra")
    #connection_details.fetch('username', "r1e3b2d6a_c684_4562_9d9d_93cdfac47840")
    connection_details.fetch('login')
  end

  def password
    #connection_details.fetch('password', "cassandra")
    #connection_details.fetch('password', "ppkmwtmizw")
    connection_details.fetch('password')
  end

  def hosts
    #connection_details.fetch('node_ips', %w[localhost])
    #connection_details.fetch('node_ips', %w[192.168.250.165])
    connection_details.fetch('contact-points').to_s.split(",").first
  end

  def port
    connection_details.fetch('port', "0").to_i
  end

  def ssl
    connection_details.fetch('ssl', false)
  end

  def connection_timeout
    connection_details.fetch('connection_timeout', 10).to_i
  end

  def remapped_connection_details
    {
        keyspace_name: keyspace_name,
        username: username,
        password: password,
      hosts: hosts,
      port: port,
      ssl: ssl,
      connection_timeout: connection_timeout,
    }
  end
end
