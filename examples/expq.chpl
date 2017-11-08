module Main{
use Cdo;
use Postgres;

proc main(){
    //Open connection with Postgres database. Parametrs are host,username, database, password

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

    // Begins new transaction
    con.Begin();

    var command =" \
    CREATE TABLE COMPANY(\
   ID INT PRIMARY KEY     NOT NULL,\
   NAME           TEXT    NOT NULL,\
   AGE            INT     NOT NULL,\
   ADDRESS        CHAR(50),\
   SALARY         REAL\
);";
    var cursor2 = con.cursor();

    cursor2.execute(command);

    cursor2.close();

// Commits the transaction
   con.commit(); 
// Rolls back the operations
// con.rollback();






        con.close();
        writeln("end");
    }
}