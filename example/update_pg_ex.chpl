module Main{
use Cdo;
use Postgres;

proc main(){
  //Open connection with Postgres database. Parametrs are host,username, database, password
    var con = PgConnectionFactory("localhost", "krishna", "teste", "krishna");
    //Open a cursor
    var cursor = con.cursor();
  

// class holding the data 
  class MyContact{
    var name:string;
    var email:string;
    proc init(name:string, email:string){
      this.name = name;
      this.email = email;
    }
  }
  var obj = new unmanaged MyContact("Carlos2", "Carlos2@carclos.com");
  // Update object in database.
  writeln(cursor.updateRecord("public.contacts","\"id\"='6'" ,obj));

//Select 
  cursor.query("SELECT * FROM public.contacts");
  //Get results
  for row in  cursor{
    writeln(row["id"]," ",row["name"]," ", row["email"]);
  }

// Data associatave array
  var data: map(string, string, parSafe = true);

  data["name"]="Maria Josef";
  data["email"]="maria@josef.com";

  //Update the db data
  writeln(cursor.update("public.contacts","\"id\"='8'" ,data));

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