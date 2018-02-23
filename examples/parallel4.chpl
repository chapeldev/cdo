module Main{
    use Cdo;
    use Postgres;
    use Time;
    
config const numTasks = here.maxTaskPar;
proc main(){
//Open connection with Postgres database. Parametrs are host,username, database, password
        var con = PgConnectionFactory("localhost", "postgres", "test", "password");
        //Open a cursor
        var cursor = con.cursor();
        cursor.query("SELECT * FROM public.contacts");

             //cursor.query(r, (fromField, toField, edgeTable, fromField, toField)); 
            const fromField="name";
            const toField="email";
            const size = cursor.rowcount(): int; 
            var dom: domain(1) = {1..size}; 
            var arr: [dom] (string, int); 
            
            var i:int =1; 
            var t: Timer; 

            t.start(); 
            
        

        for (row, i) in zip(cursor, dom) {

            arr[i]=(row[toField]: string, 1);
        }


             
            t.stop();

            for x in arr{
                writeln(x);
            }

            writeln("i=",i); 
            writeln("size=",size); 
            writeln("time=",t.elapsed());

            cursor.close();
            con.close();
            writeln("End");
    }

}