module Main{
use Cdo;
use Postgres;

proc main(){
    //Open connection with Postgres database. Parametrs are host,username, database, password
        var con = PgConnectionFactory("localhost", "postgres", "teste", "password");
        //Open a cursor
        var cursor = con.cursor();
    
    //delete conctact with id =17
    writeln(cursor.Delete("public.contacts", "\"id\"='17'")  );

//Select 
    cursor.query("SELECT * FROM public.contacts");
    //Get results
    for row in  cursor{
        writeln(row["id"]," ",row["name"]," ", row["email"]);
    }
    cursor.close();
    con.close();
    writeln("End");
  }
}