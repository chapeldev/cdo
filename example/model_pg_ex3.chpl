module Main{
  use Cdo;
  use Postgres;
  use Regexp;
  proc main(){
    var con = PgConnectionFactory("localhost", "postgres", "teste", "password");

    class Company:Model{
      var id:int;
      var name:string;
      proc Company(){
        this.setup(this);
      }
    }

    class Category:Model{
      var id:int;
      var name:string;
      proc Category(){
        this.setup(this);
      }
    }

    class ContactsCompany:Model{
      var id:int;
      var name:string;
      var email:string;
      var company_id:int;
      proc ContactsCompany(){
        this.setTable("contacts");
        this.setup(this);
      }   
    }
    var c = con.model().Find(ContactsCompany,1);
    
    if(c!=nil){
       writeln("* id = ",c.id, " name = ", c.name," email = ", c.email);

     for cat in  con.model().BelongsToMany(c,Category,"contacts_category","contact_id","category_id","id"){
         writeln("* category name = ", cat.name);
     }

    }

  var cat = con.model().Find(Category,2);
    
    if(cat!=nil){
     writeln("* category name = ", cat.name);
     coforall c in  con.model().BelongsToMany(cat, ContactsCompany,"contacts_category","category_id","contact_id"){
       writeln("* id = ",c.id, " name = ", c.name," email = ", c.email);  
     }
    }

    var category = new Category();
    category.id=2;
    con.model().Find(category);

    writeln("Category name =", category.name);

    con.close();
    writeln("End");
  }

  
}