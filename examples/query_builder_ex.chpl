module Main{
    use Cdo;
    use Postgres;
    proc main(){
            var con = PgConnectionFactory("localhost", "postgres", "teste", "password");

            var query = con.table("public.contacts");

          query.Select().Where("nome","'John'")
          .Where("email","'John@email.co'")
          .orWhere("idade","31").OrderBy(["id","name"]).OrderBy(["id","name"])
          .OrderByDesc(["age","email"])
          .OrderByDesc(["age","email"])
          .GroupBy(["age","email"])
          .GroupBy("id")
          .Limit(1).Offset(3);//.Max("id").Min("email");
          
          //query.From("'John'");
          //query.Get();
            writeln(query.toSql());

            con.close();
            
            writeln("end");
    }
}