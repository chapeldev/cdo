module Main {
    use DatabaseCommunicator;
    use DatabaseCommunicator.DatabaseCommunicationObjects;
    use DatabaseCommunicator.DatabaseCommunicationObjects.QueryBuilder;
    use MySQL;

    proc main() throws {
        var conHandler = new ConnectionHandler(MySQLConnection, "localhost;testdb;root;password");
        var cursor = conHandler.cursor();

        //var createStmt = "CREATE TABLE BLEH (id INT PRIMARY KEY, name VARCHAR(10));";
        //cursor.execute(new Statement(createStmt));
        //cursor.execute(new Statement("INSERT INTO CONTACT VALUES (6, 'B');"));
        
        //var insertStmts = [new Statement("INSERT INTO CONTACTS VALUES (1, 'A');"), new Statement("INSERT INTO CONTACTS VALUES (2, 'B');")];
        //cursor.executeBatch(insertStmts);

        var stmt: Statement = new Statement("SHOW VARIABLES LIKE '%autocommit%'", true);
        //stmt.setValue(1, "B");
        
        cursor.execute(stmt);

        for row in cursor.fetchall() {
            writeln(row![0], "\t", row![1]);
        }

        writeln(cursor.getLastError());

        // add other methods
        cursor.close();
        conHandler.commit();
        conHandler.close();
    }
}