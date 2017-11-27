module Main{
use Postgres;
use Cdo;

  proc main(){
       var con = PgConnectionFactory("localhost", "postgres", "teste", "password");
        //Open a cursor
        var cursor = con.cursor();
        cursor.query("SELECT array_agg(name)as aname FROM public.contacts");
    
    //Get results
        for row in  cursor{
            writeln("Result = ",row["aname"]);
        }

        cursor.close();
        con.close();
  }
}