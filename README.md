# cdo
Chapel Data Object

Chapel Data Object is a library that helps to connect to databases like Mysql,Postgres and Sqlite using a common API in Chapel language.

The module Cdo provides a simple way to hide the complexities that each database connector library has.

# Acknowledgment

We would like to thank [Deep 6 AI](https://deep6.ai/) for their support on this project.

We would like to thank [Brian Dolan](https://github.com/buddha314), [Ben Albrecht](https://github.com/ben-albrecht), [Brad Chamberlain](https://github.com/bradcray) 
 and all [Chapel Community](https://github.com/chapel-lang) for all motivations, suggestions and help.

## Cdo with Postgres

1. Have latest Chapel compiler version installed. 
2. Install libpq.

On Ubuntu do:
```bash
sudo apt-get install libpq-dev
```
3. Go to example/expq.chpl and inform database host, user, password. 
4. Go to repository folder and compile:
```bash
make pgsql
```
5. Run the example:
```bash
./expq
```

### Code example
```chapel
module Main{
use Cdo;
use Postgres;

proc main(){
//Open connection to Postgres database. Parametrs are host,username, database, password

var con = PgConnectionFactory("localhost", "postgres", "teste", "password");


//Open a cursor
var cursor = con.cursor();
//Queries from database
cursor.query("SELECT * FROM public.contacts");
//Get one row.
var res:Row = cursor.fetchone();
while(res!=nil){
//print the results.
writeln(res);
//get the next row one.
res = cursor.fetchone();
}

// Queries passing tuple to formated query string.
cursor.query("SELECT %s, %s FROM public.contacts",("email","name"));
        
// iterate over all rows
for row in cursor{
//get row data by column name and print it.
writeln("name = ", row["name"]," email = ", row["email"] );
}

cursor.query("SELECT * FROM public.contacts");

// iterate over all rows
for row in cursor{
//get row data by column number and print it.
writeln("name = ", row[1]," email =", row[3] );
}

cursor.close();
con.close();
writeln("end");
}
}
```

## Cdo with Mysql

1. Have latest Chapel compiler version installed. 
2. Install libmysqlclient.

On Ubuntu do:
```bash
sudo apt-get install libmysqlclient-dev
```
3. Go to example/mysql_ex1.chpl and set database host, user, password. 
4. Verify the mysql library path with ```bash mysql_config --cflags --libs ``` and edit Makefile.
5. Go to repository folder and compile:
```bash
make mysql_ex1
```
6. Run the example:
```bash
cd bin
./mysql_ex1
```

Do similar steps to compile mysql_ex2.

### Code example
```chapel
module Main {
    use DatabaseCommunicator;
    use DatabaseCommunicator.DatabaseCommunicationObjects.QueryBuilder; // for Statement class
    use MySQL;

    proc main() throws {
        var conHandler = new ConnectionHandler(MySQLConnection, "localhost;testdb;username;password");
        var cursor = conHandler.cursor();

        var createStmt = "CREATE TABLE CONTACTS (id INT PRIMARY KEY, name VARCHAR(10));";
        cursor.execute(new Statement(createStmt));
        cursor.execute(new Statement("INSERT INTO CONTACTS VALUES (6, 'B');"));

        var stmt: Statement = new Statement("SELECT * FROM CONTACTS WHERE name = ?1", true);
        stmt.setValue(1, "B");
        
        cursor.execute(stmt);

        for row in cursor.fetchall() {
            writeln(row![0], "\t", row![1]);
        }

        cursor.close();
        conHandler.commit();
        conHandler.close();
    }
}
```

If using a TOML configuration file to specify connection parameters:

```chapel
module Main {
    use DatabaseCommunicator;
    use DatabaseCommunicator.DatabaseCommunicationObjects.QueryBuilder; // for Statement class
    use MySQL;

    proc main() throws {
        var conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbinfo.toml");
        var cursor = conHandler.cursor();

        var createStmt = "CREATE TABLE CONTACTS (id INT PRIMARY KEY, name VARCHAR(10));";
        cursor.execute(new Statement(createStmt));
        cursor.execute(new Statement("INSERT INTO CONTACTS VALUES (6, 'B');"));

        var stmt: Statement = new Statement("SELECT * FROM CONTACTS WHERE name = ?1", true);
        stmt.setValue(1, "B");
        
        cursor.execute(stmt);

        for row in cursor.fetchall() {
            writeln(row![0], "\t", row![1]);
        }

        cursor.close();
        conHandler.commit();
        conHandler.close();
    }
}
```


## Cdo with Sqlite

1. Have lastest Chapel compiler version installed. 
2. Install libsqlite3-dev.

On Ubuntu do:
```bash
sudo apt-get install sqlite3 libsqlite3-dev
```
3. Go to example/exsqlite.chpl and inform database file. 
4. Go to repository folder and compile:
```bash
make sqlitex
```
5. Run the example:
```bash
./sqlitex
```

### Code example
```chapel
module Main{
use Cdo;
use Sqlite;

proc main(){
//Open connection to SQlite database. Parametrs is the file name.

var con = SqliteConnectionFactory("teste.db");

//Open a cursor
var cursor = con.cursor();
//Queries from database
cursor.query("SELECT * FROM contacts");
//Get one row using while.
var res:Row = cursor.fetchone();
while(res!=nil){
//print the results.
writeln(res);
//get the next row one.
res = cursor.fetchone();
}

// Queries passing tuple to formated query string.
cursor.query("SELECT %s, %s FROM contacts",("email","name"));
        
// iterate over all rows
for row in cursor{
//get row data by column name and print it.
writeln("name = ", row["name"]," email = ", row["email"] );
}

cursor.query("SELECT * FROM contacts");

// iterate over all rows
for row in cursor{
//get row data by column number and print it.
writeln("name = ", row[1] );
}

cursor.close();
con.close();
writeln("end");
}
}
```

# Interesting Projects
[Numsuch](https://github.com/buddha314/numsuch) numerical and Machine Learning library for Chapel Language.

# Warning

This library is very alpha and incomplete. Please, consider that we are in early stage and many functions and features are not implemented yet.
