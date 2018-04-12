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

          //Serial
          var i: int = 0;


  writeln("=== FOR LOOP ===");
  /*for row in cursor {
    writeln("from: ", row["name"], "\tto: ", row["email"]);
    i += 1;
  }*/
  //writeln("Expected  rows, got ", i, " and returnd from db ",cursor.rowcount());

            var t5= getCurrentTime(TimeUnits.milliseconds);
            
            var jj:int=0;

            var n=cursor.rowcount():int;

            var data:[{1..#n}](string,string,string);

            forall row in cursor with (ref jj){
                jj+=1;
                writeln(jj,"=>",row["id"]," name = ", row["name"]+" email = "+row["email"] );
                
                data[jj]=(row["id"],row["name"],row["email"]);
            }

            for el in data{
              writeln("*",el);
            }

            writeln("Looped over ",jj," records");
            writeln("Database returned ",cursor.rowcount()," records");


        var t6= getCurrentTime(TimeUnits.milliseconds);
        var tparallel = t6-t5;
       



    cursor.close();
    con.close();
    writeln("End");




}






iter count(n:int){
    var i=0;
    while (i<n) {
         yield i;
         i+=1;
    }
}


iter count(param tag: iterKind, n: int)
       where tag == iterKind.standalone {
  //if (verbose) then
    writeln("In count() standalone, creating ", numTasks, " tasks");
  coforall tid in 0..#numTasks {
    const myIters = computeChunk(0..#n, tid, numTasks);
    //if (verbose) then
      writeln("task ", tid, " owns ", myIters);
    for i in myIters do
      yield i;
  }
}

proc computeChunk(r: range, myChunk, numChunks) where r.stridable == false {
  const numElems = r.length;
  const elemsPerChunk = numElems/numChunks;
  const mylow = r.low + elemsPerChunk*myChunk;
  if (myChunk != numChunks - 1) {
    return mylow..#elemsPerChunk;
  } else {
    return mylow..r.high;
  }
}


}