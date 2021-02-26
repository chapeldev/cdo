/*
This example shows how to:
1. Open a connection to a MySQL database using a connection string.
2. Execute an SQL statement (here, only CREATE TABLE, INSERT, SELECT statements are shown,
   can be extended for other types of statements too).
3. Execute an SQL query after setting parameters in the query.
4. Fetching the results of the query and displaying them.
5. Close the connection.
*/
module Main {
    use DatabaseCommunicator;
    use DatabaseCommunicator.QueryBuilder; // for Statement class
    use MySQL;

    proc main() throws {
        var conHandler = ConnectionHandler.ConnectionHandlerWithString(MySQLConnection, "localhost;testdb;username;password");
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