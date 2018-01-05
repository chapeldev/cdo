module Main{
    use Cdo;
    use Postgres;
    use Regexp;

        proc main(){
            var con = PgConnectionFactory("localhost", "postgres", "test", "password");
            var cursor = con.cursor();
            var cr:PgCursor =   cursor.getDriver():PgCursor();

           var d: domain(int);
            
            d += 17;
            d += 23;
            d += 31;

            writeln(cr.pgInsertDomainInColumnArray("company","data_arr",d));

            var s:domain(string);
            s+="one";
            s+="two";
            s+="three";
           //writeln( cr.pgInsertDomainInColumnArray("company","data_str_arr",s));
            
        }


}