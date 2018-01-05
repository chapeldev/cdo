module Main{
    use Cdo;
    use Postgres;
    use Regexp;

        proc main(){
            //open connection
            var con = PgConnectionFactory("localhost", "postgres", "test", "password");
            //Get generic cursor
            var cursor = con.cursor();
            //Get native Cursor.
            //The Native cursor allows to access PostGres specific methods hidden in generic cursor.
            var native_cursor:PgCursor =   cursor.getDriver():PgCursor;
            //creates an int domain
            var d: domain(int);
            d += 17;
            d += 23;
            d += 31;
            d += 1;

            //insert into table company, column data_arr
            writeln(native_cursor.pgInsertDomainInColumnArray("company","data_arr",d));
            var s:domain(string);
            s+="one";
            s+="two";
            s+="three";
            s+="four";
            //insert into table company, column data_str_arr
            writeln(native_cursor.pgInsertDomainInColumnArray("company","data_str_arr",s));
            //update where id = 5
            writeln(native_cursor.pgUpdateDomainInColumnArray("company","data_arr",d," \"id\" = 5 "));
            writeln(native_cursor.pgUpdateDomainInColumnArray("company","data_str_arr",s," \"id\" = 5 "));
        }
}