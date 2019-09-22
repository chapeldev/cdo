module Main{
use Postgres;
use Cdo;

  proc main(){
       var con = PgConnectionFactory("localhost", "postgres", "teste", "password");
        //Open a cursor
        var cursor = con.cursor();
        cursor.query("SELECT  array_agg(name) as aname FROM public.contacts");
    
    //Get results
        for row in  cursor{
            var ret = row.getArray("aname");
            for x in ret{
                writeln("Result = "," ",x);
            }
        }

        cursor.close();
        con.close();
  }
}