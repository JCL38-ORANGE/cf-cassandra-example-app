# Example Cassandra Application

This simple application illustrates the use of the Cassandra data service in a Ruby application running on Cloud Foundry.

## Installation

#### Create a Cassandra service instance

Find your Cassandra service via `cf marketplace`.

```
$ cf marketplace
Getting services from marketplace in org testing / space testing as me...
OK

service       plans     description
cassandra   default   A simple cassandra service broker implementation
```

Our service is called `cassandra`.  To create an instance of this service, use:

```
$ cf create-service cassandra default cassandra-instance
```

#### Push the Example Application

The example application comes with a Cloud Foundry `manifest.yml` file, which provides all of the defaults necessary for an easy `cf push`.

```
$ cf push
Using manifest file cf-cassandra-example-app/manifest.yml

Creating app cassandra-example-app in org testing / space testing as me...
OK

Using route cassandra-example-app.example.com
Binding cassandra-example-app.example.com to cassandra-example-app...
OK

Uploading cassandra-example-app...
Uploading from: cf-cassandra-example-app
...
Showing health and status for app cassandra-example-app in org testing / space testing as me...
OK

requested state: started
instances: 0/1
usage: 256M x 1 instances
urls: cassandra-example-app.10.244.0.34.xip.io

     state     since                    cpu    memory          disk
#0   running   2017-10-31 01:42:43 PM   0.0%   75.5M of 256M   0 of 1G
```

If you now curl the application, you'll see that the application has detected that it's not bound to a cassandra instance.

```
$ curl http://cassandra-example-app.example.com/

      You must bind a Cassandra service instance to this application.

      You can run the following commands to create an instance and bind to it:

        $ cf create-service cassandra default cassandra-instance
        $ cf bind-service cassandra-example-app cassandra-instance
```

#### Bind the Instance

Now, simply bind the cassandra instance to our application.

```
$ cf bind-service cassandra-example-app cassandra-instance
Binding service cassandra-instance to app cassandra-example-app in org testing / space testing as me...
OK
TIP: Use 'cf push' to ensure your env variable changes take effect
$ cf push
```

## Usage

You can now create and drop tables by POSTing and DELETEing to `myTable`.

```
$ export APP=http://cassandra-example-app.example.com
$ curl -X POST $APP/myTable
$ curl -X DELETE $APP/myTable
bar
```

Of course, be sure to replace `example.com` with the actual domain of your Cloud Foundry installation.
