module Main{
use Cdo;
use Mysql;

proc main(){
    //Open connection with Postgres database. Parametrs are host,username, database, password
    var con = new MysqlConnection("localhost", "root", "teste", "krishna");        //Open a cursor
    //Open a cursor
    var cursor = con.cursor();
    
    //delete conctact with id =17
    writeln(cursor.Delete("contacts", "id='6'")  );

//Select 
    cursor.query("SELECT * FROM contacts");
    //Get results
    for row in  cursor{
        writeln(row["id"]," ",row["name"]," ", row["email"]);
    }
    cursor.close();
    con.close();
    writeln("End");
  }
}
