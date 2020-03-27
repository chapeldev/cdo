module Main{
use Cdo;
use Mysql;

proc main(){
    //Open connection with Postgres database. Parametrs are host,username, database, password

        var con = MysqlConnectionFactory("localhost", "root", "teste", "krishna");

        //Open a cursor
        var cursor = con.cursor();
        //Queries from database
        cursor.query("SELECT * FROM contacts"); 
        //Get one row.
        var res: Row? = cursor.fetchone();
        if(res != nil) {
            try! {
            const r = res: shared Row;
            writeln("name = ", r["name"]," email = ", r["email"] );
            }
        }
        while(res != nil){
            //print the results.
            writeln(res);
             
            //get the next row one.
            res = cursor.fetchone();

        }

        // Queries passing tuple to formated query string.
        cursor.query("SELECT %s, %s FROM contacts",("email","name"));
        // writeln(cursor);
        // iterate over all rows
        for row in cursor {
            res = row;
            //get row data by column name and print it.
            writeln("name = ", row["name"]," email = ", row["email"] );
        }
        writeln("Checking ");
        writeln("name = ", res!["name"]," email = ", res!["email"] );
        cursor.query("SELECT * FROM contacts");

        // iterate over all rows
        for row in cursor{
            // get row data by column number and print it.
            writeln("name = ", row[1] );
        }


        cursor.close();


// Warning: Transaction is not working propertly.
    // Begins new transaction
    con.Begin();

    var command =" \
    CREATE TABLE IF NOT EXISTS COMPANY(\
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
//    con.commit();
// Rolls back the operations
    con.rollback(); 
        con.close();
        writeln("end");
    }
}