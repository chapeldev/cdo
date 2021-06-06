module Main{
  use Cdo;
  use Mysql;
  proc main(){
      var con = new MysqlConnection("localhost", "root", "teste", "krishna");    //Open a cursor

     //var qb = new QueryBuilder( new MySqlQueryBuilder(con, "contacts"));


      con.table("contacts");
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
      
      for row in query.Select(["id","name"]).Where("name","like","%Carlos%").Get(){
      writeln(row["id"]," ",row["name"]);
      }
      query.clear();
      
      var x =  query.Where("name","like","%Carlos%").Count(); 
      writeln("count =",x);
      writeln(query.toSql());

      query.clear();
      
       x =  query.Where("name","like","%Carlos%").Count("id"); 
      writeln("count =",x);
      writeln(query.toSql());

       query.clear();
      
      var y =  query.Where("name","like","%Carlos%").Max("id"); 
      writeln("Max =",y);
      writeln(query.toSql());
      
      query.clear();
      y =  query.Where("name","like","%Carlos%").Min("id"); 
      writeln("Min =",y);
      writeln(query.toSql());
      
      query.clear();
      y =  query.Where("contacts.name","like","%Carlos%").Avg("contacts.id"); 
      writeln("Avg =",y);
      writeln(query.toSql());
      
      query.clear();
      writeln("Join count = ",query.Join("company","company.id","contacts.company_id")
      .rightJoin("company AS C2","c2.id","contacts.company_id").Count());
      writeln(query.toSql());
      
      query.clear();
      query.Delete("id","24").Exec();

      var kvDom:domain(string);
      var kv:[kvDom]string;
      kv["name"]="Patrick";
      kv["email"]="patrick@email.co";
      query.Insert(kv).Exec();
      writeln(query.toSql());
      
      query.clear();

      for row in query.Select(["id","name"]).Get(){
      writeln(row["id"]," ",row["name"]," ",row["email"]);
      }
      
      query.clear();
      */ 
      con.close();
      writeln("end");
  }
}