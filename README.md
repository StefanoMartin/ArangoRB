ArangoRB
===============================

[ArangoDB](https://www.arangodb.com/) is a native multi-model database with flexible data models for document, graphs, and key-values.
ArangoRB would like to be a Ruby Gem to use ArangoDB with Ruby. ArangoRB is based on the [HTTP API of ArangoDB](https://docs.arangodb.com/3.0/HTTP/index.html).

ArangoRB has been tested with ArangoDB 3.0 on Ruby 2.3.1. It requires the gem "HTTParty"

At the moment ArangoRB is not a Gem: to install it clone the project, create a link in your project and then use
`require_relative "./ArangoRB/ArangoRB"` in your ruby code.

When it will be a gem you can use `require "arangorb"`.

## Classes used

ArangoRB has the following classes.

* [ArangoS](#arangos): to manage the global variables for the management of the database
* [ArangoDB](#arangodb): to manage a Database
* [ArangoC](#arangoc): to manage a Collection
* [ArangoDoc](#arangodoc): to manage a Document
* [ArangoV](#arangov): to manage a Vertex
* [ArangoE](#arangoe): to manage an Edge
* [ArangoG](#arangog): to manage a Graph
* [ArangoT](#arangot): to manage a Traverse operation
* [ArangoAQL](#arangoaql): to manage an AQL instance

<a name="arangos"></a>
## ArangoS - ArangoDB Server

ArangoS is used to manage global variables for the management of the database and it is the mandatory step to start your database.

To setup your server use:

``` ruby
ArangoS.default_server user: "Username", password: "MyPass", server: "localhost", port: "8529"
```

Default value for the server are user: "root", server: "localhost", port: "8529". Password must be defined.

### Global variables

The databases, graphs and collections used in your program can be defined every time. But often the user needs to use only a single database, a single graph and a single collection.
If this is the case, the user can use ArangoS to define this value once for all the ArangoRB instances.

``` ruby
ArangoS.database = "MyDatabase"
ArangoS.graph = "MyGraph"
ArangoS.collection = "MyCollection"
```

By default the global database is "\_system".

### Verbose

For Debugging reasons the user sometimes would like to receive the original JSON file from the database. To do this you can use the verbose command.

``` ruby
ArangoS.verbose = true
```

Remember that verbose is only for testing reason: to work efficiently verbose should be false.

<a name="arangodb"></a>
## ArangoDB - ArangoDB Database

ArangoDB is used to manage your Database. You can create an instance in the following way:

``` ruby
myDatabase = ArangoDB.new(database: "MyDatabase")
```

Alternatively, you can use ArangoS:

``` ruby
ArangoS.database = "MyDatabase"
myDatabase = ArangoDB.new
```

### Create and Destroy a Database

``` ruby
myDatabase.create
mmyDatabase.destroy
```

### Retrieve information

``` ruby
ArangoDB.info # Obtain general info about the databases
ArangoDB.databases # Obtain an Array with the available databases
myDatabase.collections # Obtain an Array with the available collections in the selected Database
myDatabase.graphs #  Obtain an Array with the available graphs in the selected Database
```

### Query

``` ruby
myDatabase.propertiesQuery; # See property of the Query
myDatabase.currentQuery; # Check the current Query
myDatabase.slowQuery; # Find slow queries
myDatabase.stopSlowQuery; # Stop slow queries
myDatabase.kill id: myQuery.id # Kill a Query
myDatabase.changePropertiesQuery maxSlowQueries: 65 # Change properties of a Query
```

### Cache

``` ruby
myDatabase.clearCache # Clear Cache
myDatabase.propertyCache # Check properties Cache
myDatabase.changePropertyCache maxResults: 30 # Change properties Cache
```

### AQL Functions

``` ruby
myDatabase.createFunction code: "function(){return 1+1;}", name: "myFunction" # Create a new Function
myDatabase.deleteFunction name: "myFunction" # Delete a function
myDatabase.functions # Retrieve a list of the available functions
```
<a name="arangoc"></a>
## ArangoC - ArangoDB Collection

ArangoDB is used to manage your Collections. You can create an ArangoC instance in one of the following way:

``` ruby
myCollection = ArangoC.new(database: "MyDatabase", collection: "MyCollection")
myCollection = ArangoC.new(collection: "MyCollection") # If the database has been already defined with ArangoS
myCollection = ArangoC.new # If the database and the collection have been already defined with ArangoS
```

A Collection can be of two types: "Document" and "Edge". If you want to specify it, uses:

``` ruby
myCollectionA = ArangoC.new collection: "MyCollectionA", type: "Document"
myCollectionB = ArangoC.new collection: "MyCollectionB", type: "Edge"
```

### Create a Collection

`myCollection.create`

If not specified the default type of the Collection is "Document".
To create an Edge Collection you can use one of the next three options:

``` ruby
myCollection.create_edge_collection
myCollection.create type: 3
myCollectionB = ArangoC.new(collection: "MyCollectionB", type: "Edge");  myCollectionB.create
```

### Destroy or Truncate a Collections

Destroy will delete from the Database the selected Collection.

`myCollection.destroy`

Truncate will delete all the Documents inside the selected Collection.

`myCollection.truncate`

### Retrieve information

``` ruby
myCollection.retrieve # Retrieve the selected Collection
myCollection.properties # Properties of the Collection
myCollection.count # Number of Documents in the Collection
myCollection.stats # Statistics of the Collection
myCollection.checksum
```

To retrieve the documents of a Collection you can use:

``` ruby
myCollection.documents
myCollection.allDocuments
```

These two functions are similar except for the fact that you can assign different variables.

`myCollection.documents type: "path"`

Type can be "path", "id" or "key" in relation what we wish to have. If not specified we will receive an array of ArangoDoc instances.

`myCollection.allDocuments skip: 3, limit: 100, batchSize: 10`

It means that we skip the first three Documents, we can retrieve the next 100 Documents but we return only the first ten.

To retrieve specific Document you can use:

``` ruby
myCollection.documentsMatch match: {"value" => 4} # All Documents of the Collection with value equal to 4
myCollection.documentMatch match: {"value" => 4} # The first Document of the Collection with value equal to 4
myCollection.documentByKeys keys: ["4546", "4646"] # Documents of the Collection with the keys in the Array
myCollection.random # A random Document of the Collection
```

### Modify the Collection

``` ruby
myCollection.load # Load the Collection
myCollection.unload  # Unload the Collection
myCollection.change waitForSync: true  # Change a property of the Collection
myCollection.rename "myCollectionC"  # Rename the Collection
```

### Other operations

``` ruby
myCollection.removeByKeys keys: ["4546", "4646"] # Documents of the Collection with the keys in the Array will be removed
myCollection.removeMatch match: {"value" => 4} # All Documents of the Collection with value equal to 4 will be removed
myCollection.replaceMatch match: {"value" => 4}, newValue: {"value" => 6} # All Documents of the Collection with value equal to 4 will be replaced with the new Value
myCollection.updateMatch match: {"value" => 4}, newValue: {"value" => 6} # All Documents of the Collection with value equal to 4 will be updated with the new Value
```

<a name="arangodoc"></a>
## ArangoDoc - ArangoDB Document

An Arango Document is an element of a Collection. Edges are documents with "\_from" and "\_to" in their body.
You can create an ArangoC instance in one of the following way:

``` ruby
myDocument = ArangoDoc.new(database: "MyDatabase", collection: "MyCollection", key: "myKey")
myDocument = ArangoDoc.new(collection: "MyCollection", key: "myKey") # If the database has been already defined with ArangoS
myDocument = ArangoDoc.new(collection: myCollection, key: "myKey") # If the database has been already defined with ArangoS and myCollection is an ArangoC instance
myDocument = ArangoDoc.new(key: "myKey") # If the database and the collection have been already defined with ArangoS
myDocument = ArangoDoc.new # If the database and the collection have been already defined with ArangoS and I don't want to define a key for my Instance
```

In the case you want to define a Edge, it is convenient to introduce them during the instance.

``` ruby
myEdge = ArangoDoc.new from: myDocA, to: myDocB
```

where myDocA and myDocB are the IDs of two Documents or are two ArangoDoc instances.

When you do the instance of an ArangoDoc is a good idea to define a Body for the Document you want:

``` ruby
myDocument = ArangoDoc.new(body: {"value" => 17})
```

### Create one or more Documents

You have three way to create a single Document.

``` ruby
myDocument.create
myCollection.create_document document: myDocument # myDocument is an ArangoDoc instance or a Hash
ArangoDoc.create(body: {"value" => 17}, collection: myDocument)
```

You have two way to create more Documents.

``` ruby
myCollection.create_document document: [myDocumentA, myDocumentB, {"value" => 17}] # Array of ArangoDoc instances and Hashes
ArangoDoc.create(body: [{"value" => 17}, {"value" => 18}, {"value" => 3}], collection: myDocument)  # Array of only Hashes
```

### Create one or more Edges

We have different way to create one or multiple edges. Here some example:

``` ruby
myEdge = ArangoDoc.new from: myDocA, to: myDocB; myEdge.create
myEdge.create_edge from: myDocA, to: myDocB # myDocA and myDocB are ArangoDoc ids or ArangoDoc instances
myEdgeCollection.create_edge document: myEdge, from: myDocA, to: myDocB
ArangoDoc.create_edge(body: {"value" => 17}, from: myDocA, to: myDocB, collection: myEdgeCollection)
```

Further we have the possibility to create different combination of Edges in only one line of code

One-to-one with one Edge class

 * [myDocA] --(myEdge)--> [myDocB]

``` ruby
myEdgeCollection.create_edge document: myEdge, from: myDocA, to: myDocB
```

One-to-more with one Edge class (and More-to-one with one Edge class)

 * [myDocA] --(myEdge)--> [myDocB]
 * [myDocA] --(myEdge)--> [myDocC]

 ``` ruby
myEdgeCollection.create_edge document: myEdge, from: myDocA, to: [myDocB, myDocC]
```

More-to-More with one Edge class

 * [myDocA] --(myEdge)--> [myDocC]
 * [myDocB] --(myEdge)--> [myDocC]
 * [myDocA] --(myEdge)--> [myDocD]
 * [myDocB] --(myEdge)--> [myDocD]

 ``` ruby
myEdgeCollection.create_edge document: myEdge, from: [myDocA, myDocB], to: [myDocC, myDocD]
```

More-to-More with more Edge classes

 * [myDocA] --(myEdge)--> [myDocC]
 * [myDocB] --(myEdge)--> [myDocC]
 * [myDocA] --(myEdge)--> [myDocD]
 * [myDocB] --(myEdge)--> [myDocD]
 * [myDocA] --(myEdge2)--> [myDocC]
 * [myDocB] --(myEdge2)--> [myDocC]
 * [myDocA] --(myEdge2)--> [myDocD]
 * [myDocB] --(myEdge2)--> [myDocD]

 ``` ruby
myEdgeCollection.create_edge document: [myEdge, myEdge2], from: [myDocA, myDocB], to: [myDocC, myDocD]
```

### Destroy a Document

``` ruby
myDocument.destroy
```

### Retrieve information

``` ruby
myDocument.retrieve # Retrieve Document
myDocument.retrieve_edges(collection: myEdgeCollection) # Retrieve all myEdgeCollection edges connected with the Document
myDocument.any(myEdgeCollection) # Retrieve all myEdgeCollection edges connected with the Document
myDocument.in(myEdgeCollection)  # Retrieve all myEdgeCollection edges coming in the Document
myDocument.out(myEdgeCollection) # Retrieve all myEdgeCollection edges going out the Document
myEdge.from # Retrieve the document at the begin of the edge
myEdge.to # Retrieve the document at the end of the edge
```

#### Example: how to navigate the edges

Think for example that we have the following schema:
 * A --[class: a, name: aa]--> B
 * A --[class: a, name: bb]--> C
 * A --[class: b, name: cc]--> D
 * B --[class: a, name: dd]--> E

Then we have:

 * A.retrieve is A
 * A.retrieve_edges(collection: a) is [aa, bb]
 * B.any(a) is [aa, dd]
 * B.in(a) is [aa]
 * B.out(a) is [dd]
 * aa.from is A
 * aa.to is B

We can even do some combinations: for example A.out(a)[0].to.out(a)[0].to is E since:
 * A.out(a) is [aa]
 * A.out(a)[0] is aa
 * A.out(a)[0].to is B
 * A.out(a)[0].to.out(a) is [dd]
 * A.out(a)[0].to.out(a)[0] is dd
 * A.out(a)[0].to.out(a)[0].to is E

### Modify

``` ruby
myDocument.update body: {"value" => 3} # We update or add a value
myDocument.replace body: {"value" => 3} # We replace a value
```

<a name="arangog"></a>
## ArangoG - ArangoDB Graph

ArangoG are used to manage graphs. You can create an ArangoG instance in one of the following way:

``` ruby
myGraph = ArangoG.new(database: "MyDatabase", graph: "MyGraph")
myGraph = ArangoG.new(graph: "MyGraph") # If the database has been already defined with ArangoS
myGraph = ArangoG.new # If the database and the graph have been already defined with ArangoS
```

### Create, Retrieve and Destroy a Graph

``` ruby
myGraph.create # create a new Graph
myGraph.retrieve # retrieve the Graph
myGraph.destroy # destroy the Graph
```

### Manage Vertex Collections

``` ruby
myGraph.vertexCollections # Retrieve all the vertexCollections of the Graph
myGraph.addVertexCollection(collection: "myCollection") # Add a Vertex Collection to our Graph
myGraph.removeVertexCollection(collection: "myCollection") # Remove a Vertex Collection to our Graph
```

### Manage Edge Collections

``` ruby
myGraph.edgeCollections # Retrieve all the edgeCollections of the Graph
myGraph.addEdgeCollections(collection: "myEdgeCollection", from: "myCollectionA", to: "myCollectionB") # Add an Edge Collection to our Graph
myGraph.replaceEdgeCollections(collection: "myEdgeCollection", from: "myCollectionA", to: "myCollectionB") # Replace an Edge Collection to our Graph
myGraph.removeEdgeCollections(collection: "myEdgeCollection") # Remove an Edge Collection to our Graph
```

<a name="arangov"></a><a name="arangoe"></a>
## ArangoV - ArangoDB Vertex and ArangoE - ArangoDB Edge

Both these two classes inherit the class ArangoDoc.
These two classes has been created since ArangoDB offers, in connection of the chosen graph, other possible HTTP request to fetch Vertexes and Edges.

### ArangoV methods

ArangoV inherit all the methods of ArangoDoc class. The following one works similar to the one of ArangoDoc Class but use a different HTTP request. For this reason the performance could be different.
To use ArangoV, the Collection of the Vertex needs to be added to the VertexCollections of the chosen Graph.

``` ruby
myVertex = ArangoV.new key: "newVertex", body: {"value" => 3}, collection: "myCollection", graph: "myGraph", database: "myDatabase"
myVertex.create # create a new Document in the Graph
myVertex.retrieve  # retrieve a Document
myVertex.replace body: {"value" => 6} # replace the Document
myVertex.update body: {"value" => 6} # update the Document
myVertex.destroy # delete the Document
```

### ArangoE methods

ArangoE inherit all the methods of ArangoDoc class. The following one works similar to the one of ArangoDoc Class but use a different HTTP request. For this reason the performance could be different.
To use ArangoE, the Collection of the Edge needs to be added to the EdgeCollections of the chosen Graph.

``` ruby
myEdge = ArangoE.new key: "newVertex", body: {"value" => 3}, from: myArangoDoc, to: myArangoDoc, collection: "myCollection", graph: "myGraph", database: "myDatabase"
myEdge.create # create a new Document of type Edge in the Graph
myEdge.retrieve # retrieve a Document
myEdge.replace body: {"value" => 6} # replace the Document
myEdge.update body: {"value" => 6} # update the Document
myEdge.destroy # delete the Document
```

<a name="arangot"></a>
## ArangoT - ArangoDB Transaction

ArangoT is used to administrate the transaction.
ArangoT needs to know the vertex from where the transaction starts, the direction the transaction is going and either the Graph or the EdgeCollection we want to analize.

``` ruby
myTransaction = ArangoT.new # create new ArangoTransaction
myTransaction.vertex = myVertex # define starting Vertex
myTransaction.graph = myGraph  # define used Graph
myTransaction.edgeCollection = myEdgeCollection # define used Edge
myTransaction.in # Direction is in
myTransaction.out  # Direction is out
myTransaction.any  # Direction is in and out
myTransaction.min = 1 # Define how minimum deep we want to go with the transaction
myTransaction.max = 3 # Define how maximum deep we want to go with the transaction
```

After the transaction is setup, you can execute it:

``` ruby
myTransaction.execute
```

<a name="arangoaql"></a>
## ArangoAQL - ArangoDB Query Language

ArangoAQL is used to manage the ArangoDB query languages. To instantiate a query use:

``` ruby
myQuery = ArangoAQL.new(query: "FOR v,e,p IN 1..6 ANY 'Year/2016' GRAPH 'MyGraph' FILTER p.vertices[1].num == 6 && p.vertices[2].num == 22 && p.vertices[6]._key == '424028e5-e429-4885-b50b-007867208c71' RETURN [p.vertices[4].value, p.vertices[5].data]")
```

To execute it use:
``` ruby
myQuery.execute
```

If the query is too big, you can divide the fetching in piece, for example:
``` ruby
myQuery.size = 10
myQuery.execute # First 10 documents
myQuery.next # Next 10 documents
myQuery.next # Next 10 documents
```

### Check property query

``` ruby
myQuery.explain # Show data query
myQuery.parse # Parse query
myQuery.properties;  # Check properties
myQuery.current; # Retrieve current Query
myQuery.slow; # Retrieve slow Queries
myQuery.changeProperties maxSlowQueries: 65 # Change Properties
```

### Delete query

``` ruby
myQuery.stopSlow; # Stop Slow query
myQuery.kill; # Kill Query
```
