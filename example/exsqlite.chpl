module Main{
use Cdo;
use Sqlite;

proc main(){
    //Open connection with SQlite database. Parametrs is the file name.

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

    con.Begin();

    var command =" \
    CREATE TABLE COMPANY(\
   ID  INTEGER PRIMARY KEY     NOT NULL,\
   NAME           TEXT    NOT NULL,\
   AGE            INT     NOT NULL,\
   ADDRESS        TEXT,\
   SALARY         REAL\
);";
    var cursor2 = con.cursor();

    cursor2.execute(command);

    cursor2.close();

// Commits the transaction
//    con.commit(); 
// Rolls back the operations
 con.rollback();





        con.close();
        writeln("end");
    }
}