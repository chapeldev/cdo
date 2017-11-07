module Main{
use Cdo;
use Mysql;

proc main(){
    //Open connection with Postgres database. Parametrs are host,username, database, password

        var con = MysqlConnectionFactory("localhost", "root", "teste", "root");


        //Open a cursor
        var cursor = con.cursor();
        //Queries from database
        cursor.query("SELECT * FROM contacts"); 
        //Get one row.
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