module Main{
    use Cdo;
    use Postgres;
    proc main(){
            var con = PgConnectionFactory("localhost", "postgres", "teste", "password");

            var query = con.table("public.contacts");

          /*query.Select(["id","name"]).Where("nome","'John'")
          .Where("email","'John@email.co'")
          .orWhere("idade","31")
          .WhereIn("id",["1","2","3"])
          .WhereBetween("id","1","3")
          .WhereNotBetween("id","1","3")
          .orWhereNotBetween("id","1","3")
          .OrderBy(["id","name"]).OrderBy(["id","name"])
          .OrderByDesc(["age","email"])
          .OrderByDesc(["age","email"])
          .GroupBy(["age","email"])
          .GroupBy("id")
          .Limit(1)
          .Offset(3)
          .Count("id");          
*/
          for row in query.Select(["id","name"]).Where("name","like","%Carlos%").WhereBetween("id","4","6").Get(){
            writeln(row["id"]," ",row["name"]);
          }
            writeln(query.toSql());
            con.close();  
            writeln("end");
    }
}