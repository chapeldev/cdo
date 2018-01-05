module Main{

    use Cdo;
    use Postgres;
    use Regexp;

        proc main(){
            var con = PgConnectionFactory("localhost", "postgres", "test", "password");
            var cursor = con.cursor();
            
        
        }


}