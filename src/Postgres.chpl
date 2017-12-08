/*
 * Copyright (C) 2016 Marcos Cleison Silva Santana
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module Postgres{
    use SysBasic;
    use Cdo;
    use PostgresNative;
    use IO.FormattedIO;
    use Types;

    require "libpq-fe.h","-lpq";
    require "stdio.h";


proc PgConnectionFactory(host:string, user:string="", database:string="", passwd:string=""):Connection{

  return new Connection(new PgConnection(host, user, database, passwd));
}

class PgConnection:ConnectionBase{

     var dsn:string;
     var conn:c_ptr(PGconn);
    // var mapperDom:domain(string); //When I declare this the compiler says that there is an error
    // var type_mapper:[mapperDom]string; 
    
     proc PgConnection(host:string, user:string="", database:string="", passwd:string=""){
        try{
            this.dsn="postgresql://%s:%s@%s/%s".format(user,passwd,host,database);
           // writeln("conecting to ",this.dsn);
            this.conn = PQconnectdb(this.dsn.localize().c_str());
            if (PQstatus(conn) != CONNECTION_OK)
            {
                var err=new string(PQerrorMessage(conn):c_string);
                writeln("Connection to database failed: ",err);
                PQfinish(conn);
                halt("Error");
            }
            this.__registerTypes();
        }catch{
                writeln("Postgres Connection to database exception");
        }
         
     }

    proc getNativeConection(): c_ptr(PGconn){
        return this.conn;   
    }

    proc helloWorld(){
        writeln("Hello from PgConnection");
    }

    proc cursor(){
        return new Cursor(new PgCursor(this,this.conn));
    }
    proc Begin(){
        var res = PQexec(this.conn, "BEGIN");
        if (PQresultStatus(res) != PGRES_COMMAND_OK)
        {
            //Todo: Improve error messages
             //PQerrorMessage(conn));
            PQclear(res);

            halt("error");
        }

        PQclear(res);
    }

    proc commit(){
    var res = PQexec(this.conn, "COMMIT");
        if (PQresultStatus(res) != PGRES_COMMAND_OK)
        {
            //Todo: Improve error messages
             //PQerrorMessage(conn));
            PQclear(res);

            halt("error");
        }

        PQclear(res);
    }
    proc rollback(){
        var res = PQexec(this.conn, "ROLLBACK");
        if (PQresultStatus(res) != PGRES_COMMAND_OK)
        {
            //Todo: Improve error messages
             //PQerrorMessage(conn));
            PQclear(res);

            halt("error");
        }
        PQclear(res);

    }
    proc close(){
        PQfinish(this.conn);
    }

    proc table(table:string){
        return new QueryBuilder(new PgQueryBuilder(this,table));
    }

    proc model():ModelEngine{
        var engine = new ModelEngine(new Connection(this));
        return engine;
    }

    proc __registerTypes(){
       /* this.__registerTypeName(20, "int"); // int8
        this.__registerTypeName(21, "int"); // int2
        this.__registerTypeName(23, "int"); // int4
        this.__registerTypeName(26, "int"); // oid
        this.__registerTypeName(700, "real"); // float4/real
        this.__registerTypeName(701, "real"); // float8/double
        this.__registerTypeName(16, "bool");
        this.__registerTypeName(1082, "date"); // date
        this.__registerTypeName(1114, "date"); // timestamp without timezone
        this.__registerTypeName(1184, "date"); // timestamp
        this.__registerTypeName(600, "point"); // point
        this.__registerTypeName(651, "string-array"); // cidr[]
        this.__registerTypeName(718, "string"); // circle
        this.__registerTypeName(1000, "bool-Array");
        this.__registerTypeName(1001, "string-Array");
        this.__registerTypeName(1005, "int-array"); // _int2
        this.__registerTypeName(1007, "int-array"); // _int4
        this.__registerTypeName(1028, "int-array"); // oid[]
        this.__registerTypeName(1016, "integer-array"); // _int8
        this.__registerTypeName(1017, "point-array"); // point[]
        this.__registerTypeName(1021, "real-array"); // _float4
        this.__registerTypeName(1022, "real-array"); // _float8
        this.__registerTypeName(1231, "real-array"); // _numeric
        this.__registerTypeName(1014, "string-array"); //char
        this.__registerTypeName(1015, "string-array"); //varchar
        this.__registerTypeName(1008, "string-array");
        this.__registerTypeName(1009, "string-array");
        this.__registerTypeName(1040, "string-array"); // macaddr[]
        this.__registerTypeName(1041, "string-array"); // inet[]
        this.__registerTypeName(1115, "date-array"); // timestamp without time zone[]
        this.__registerTypeName(1182, "date-array"); // _date
        this.__registerTypeName(1185, "date-array"); // timestamp with time zone[]
        this.__registerTypeName(1186, "range");
        this.__registerTypeName(17, "string");
        this.__registerTypeName(114, "json"); // json
        this.__registerTypeName(3802, "json"); // jsonb
        this.__registerTypeName(199, "json-array"); // json[]
        this.__registerTypeName(3807, "json-array"); // jsonb[]
        this.__registerTypeName(3907, "string-array"); // numrange[]
        this.__registerTypeName(2951, "string-array"); // uuid[]
        this.__registerTypeName(791, "string-array"); // money[]
        this.__registerTypeName(1183, "string-array"); // time[]
        this.__registerTypeName(1270, "string-array"); // timetz[]
        */

    }

   /* proc __registerTypeName(oid:int, cdo_type:string){
        //this.__type_mapper[oid:string]= cdo_type;
    }
    proc __typeToString(oid:Oid):string{
        //return this.__type_mapper[oid:string];
    }
    */
    proc dumpt(){
       
        
    }

}

class PgCursor:CursorBase{
    
   var con:PgConnection;
   var pgcon:c_ptr(PGconn);
   var res:c_ptr(PGresult);

   var mapperDom:domain(string); //When I declare this the compiler says that there is an error
   var type_mapper:[mapperDom]string; 
 
   
   var nFields:int(32);
   var numRows:int(32);
   var curRow:int(32)=0;

   proc PgCursor(con:PgConnection, pgcon:c_ptr(PGconn)){
       this.con = con;
       this.pgcon=pgcon;
       this.__registerTypes();
   }

    proc __registerTypes(){
        this.__registerTypeName(20, "int"); // int8
        this.__registerTypeName(1043, "string"); // macaddr[]
        this.__registerTypeName(21, "int"); // int2
        this.__registerTypeName(23, "int"); // int4
        this.__registerTypeName(26, "int"); // oid
        this.__registerTypeName(700, "real"); // float4/real
        this.__registerTypeName(701, "real"); // float8/double
        this.__registerTypeName(16, "bool");
        this.__registerTypeName(1082, "date"); // date
        this.__registerTypeName(1114, "date"); // timestamp without timezone
        this.__registerTypeName(1184, "date"); // timestamp
        this.__registerTypeName(600, "point"); // point
        this.__registerTypeName(651, "string-array"); // cidr[]
        this.__registerTypeName(718, "string"); // circle
        this.__registerTypeName(1000, "bool-Array");
        this.__registerTypeName(1001, "string-Array");
        this.__registerTypeName(1005, "int-array"); // _int2
        this.__registerTypeName(1007, "int-array"); // _int4
        this.__registerTypeName(1028, "int-array"); // oid[]
        this.__registerTypeName(1016, "integer-array"); // _int8
        this.__registerTypeName(1017, "point-array"); // point[]
        this.__registerTypeName(1021, "real-array"); // _float4
        this.__registerTypeName(1022, "real-array"); // _float8
        this.__registerTypeName(1231, "real-array"); // _numeric
        this.__registerTypeName(1014, "string-array"); //char
        this.__registerTypeName(1015, "string-array"); //varchar
        this.__registerTypeName(1008, "string-array");
        this.__registerTypeName(1009, "string-array");
        this.__registerTypeName(1040, "string-array"); // macaddr[]
        this.__registerTypeName(1041, "string-array"); // inet[]
        this.__registerTypeName(1115, "date-array"); // timestamp without time zone[]
        this.__registerTypeName(1182, "date-array"); // _date
        this.__registerTypeName(1185, "date-array"); // timestamp with time zone[]
        this.__registerTypeName(1186, "range");
        this.__registerTypeName(17, "string");
        this.__registerTypeName(114, "json"); // json
        this.__registerTypeName(3802, "json"); // jsonb
        this.__registerTypeName(199, "json-array"); // json[]
        this.__registerTypeName(3807, "json-array"); // jsonb[]
        this.__registerTypeName(3907, "string-array"); // numrange[]
        this.__registerTypeName(2951, "string-array"); // uuid[]
        this.__registerTypeName(791, "string-array"); // money[]
        this.__registerTypeName(1183, "string-array"); // time[]
        this.__registerTypeName(1270, "string-array"); // timetz[]
        

    }

    proc __registerTypeName(oid:int, cdo_type:string){
        this.type_mapper[oid:string]= cdo_type;
    }
    proc __typeToString(oid:Oid):string{
        if(this.mapperDom.member(oid:string)){
            return this.type_mapper[oid:string];
        }
        return oid:string;        
    }
   

    proc rowcount():int(32){
        return this.numRows;
    }


    proc callproc(){

    }

    proc close(){

        PQclear(this.res);    
    }

    proc execute(query:string, params){
        try{
            this.execute(query.format((...params)));
        }catch{
            writeln("Error");
        }
    }

    proc execute(query:string){
        this.res = PQexec(this.pgcon, query.localize().c_str());
        if (PQresultStatus(res) !=  PGRES_COMMAND_OK)
        {
            var err = new string(PQerrorMessage(this.pgcon):c_string);
            writeln("Failed to fetch results: ",err);
            PQclear(res);
            PQfinish(this.pgcon);       
            halt("Error");
        }

        this.__removeColumns();
        this.nFields = PQnfields(this.res);

        var ii:int(32)=0;
        while ( ii < nFields){    
            var colname = new string(PQfname(this.res, ii:c_int));
            var coltype = this.__typeToString(PQftype(this.res,ii:c_int));
            //this.con.__typeToString(PQftype(this.res,ii:c_int):int
            this.__addColumn(ii,colname, coltype );
            ii+=1;
        }
        this.numRows =PQntuples(res):int(32);
        this.curRow=0;
    }

    proc query(query:string){
          this.res = PQexec(this.pgcon, query.localize().c_str());
        if (PQresultStatus(res) != PGRES_TUPLES_OK)
        {
            var err = new string(PQerrorMessage(this.pgcon):c_string);
            writeln("Failed to fetch results: ",err);
            PQclear(res);
            PQfinish(this.pgcon);       
            halt("Error");
            //return -1;
        }

        this.__removeColumns();
        this.nFields = PQnfields(this.res);

        var ii:int(32)=0;
        while ( ii < nFields){    
            var colname = new string(PQfname(this.res, ii:c_int));
            var coltype = this.__typeToString(PQftype(this.res,ii:c_int));
            this.__addColumn(ii,colname, coltype );
            ii += 1;
        }
        this.numRows =PQntuples(res):int(32);
        this.curRow=0;
        //return this.numRows;
   }

    proc query(query:string, params){
        try{
            this.query(query.format((...params)));
        }catch{
            writeln("Error");
        }
    }

    proc dump(){
        var res = this.res;
        var  i=0;
        var j=0;
        var row = "";
        var rows = PQntuples(res):int;
        while ( i < rows)
        {       
            j=0;
            while(j < this.nFields){
                row = new string(PQgetvalue(res, i:c_int, j:c_int):c_string);

            // printf("\t%s".localize().c_str(),PQgetvalue(res,  i:c_int, j:c_int));
                write("\t",row);
           //write("\t",PQgetvalue(res,  i:c_int, j:c_int):string);
           
                j+=1;
            }       
            writeln("\n");
            i+=1;
        }
    }
    
    proc executemany(str:string, data:[?D]?eltType){
        try{
           for datum in data{
               writeln(str.format((...datum)));
           }
        }catch{
            writeln("Error");
        }
    }

    proc fetchrow(idx:int):Row{
        if(idx > this.rowcount()){
            return nil;
        }
        var row = new Row();
       
        var j:int(32)=0;

        this.curRow = idx:int(32);

        while(j < this.nFields){
                var datum = new string(PQgetvalue(res, this.curRow:c_int, j:c_int):c_string);
                var colinfo = this.getColumnInfo(j);
                //this.__addColumn(ii,colname, coltype );
                row.addData(colinfo.name,datum,colinfo.coltype);
                j += 1;
        }
        this.curRow += 1;
        return row;
    }

    proc this(idx:int):Row{

        return this.fetchrow(idx);
    }

    iter these()ref:Row{
        for row in this.fetchall(){
            yield row;
        }
    }

    proc fetchone():Row{
        if(this.curRow==this.numRows){
           return nil;
        }
       var row = new Row();
       
       var j:int(32)=0;
       while(j < this.nFields){
                var datum = new string(PQgetvalue(res, this.curRow:c_int, j:c_int):c_string);
                var colinfo = this.getColumnInfo(j);
                 row.addData(colinfo.name,datum,colinfo.coltype);
                j += 1;
        }
        this.curRow += 1;
        return row;
    }
    iter fetchmany(count:int=0):Row {
        if(count<=0){

            for row in this.fetchall(){
                yield row;
            } 
             
        }else{
            var idx=0;
            var res:Row = this.fetchone();    
            while((res!=nil)&&(idx<this.rowcount())&&(idx<count)){
                yield res;
                res = this.fetchone();
                idx+=1;
            }
        }
    }
    iter fetchall():Row{
        //var rowsDomain:domain(1)={0..1};
        //var rows:[rowsDomain]Row;

        var res:Row = this.fetchone();
        while(res!=nil){
            yield res;
            res = this.fetchone();
        }
        
    }

    proc next():Row{
        return this.fetchone();
    }

    proc messages(){

    }
    proc __quote_columns(colname:string):string{
        if(colname=="*"){
            return "*";
        }

        return "\""+colname+"\"";
    }
    proc __quote_values(value:string):string{
        return "'"+value+"'";
    }
    proc insertRecord(table:string, ref el:?eltType):string{

        var cols = this.__objToArray(el);
        return this.insert(table, cols);       
    }
    proc insert(table:string, data:[?D]string):string{
        var colset:[{1..0}]string;
        var valset:[{1..0}]string;

         for idx in D{
            colset.push_back(this.__quote_columns(idx));
            valset.push_back(this.__quote_values(data[idx]));
        }
        var cols_part = ", ".join(colset);
        var vals_part = ", ".join(valset);
        var sql="";
        try{
            sql = "INSERT INTO %s(%s) VALUES(%s) ".format(table, cols_part, vals_part);
        }catch{
            writeln("Error on building insert query");
        }
         this.execute(sql);
         return sql;
    }
    proc update(table:string, whereCond:string, data:[?D]string):string{
        var colvalset:[{1..0}]string; 
        for idx in D{
            colvalset.push_back(this.__quote_columns(idx)+" = "+this.__quote_values(data[idx]));
        }
        var colsvals_part = ", ".join(colvalset);
        var sql="";
        try{
            sql = "UPDATE %s SET %s WHERE (%s)".format(table, colsvals_part, whereCond);
        }catch{
            writeln("Error on building update query");
        }
         this.execute(sql);
         return sql;
    }

    proc update(table:string, whereCond:string, ref el:?eltType):string{
        var cols = this.__objToArray(el);
        return this.update(table, whereCond, cols);
    }

    proc updateRecord(table:string, whereCond:string, ref el:?eltType):string{
        return this.update(table,whereCond,el);
    }
    proc Delete(table:string, whereCond:string):string{
        var sql ="";
        try{
            sql = "DELETE FROM %s WHERE (%s)".format(table,whereCond);
        }catch{
            writeln("Error on formating delete statement");
        }
        this.execute(sql);
        return sql;
    }
}

class PgQueryBuilder: QueryBuilderBase{
   var sql:string="";
   var conn:PgConnection;
   var cursor:Cursor;
   //var table:string;

   var _orderby_declared:bool=false;
   var _operation_type:string;

   proc PgQueryBuilder(con:PgConnection, table:string){
       this.conn = con;       
       this.From(table);
       this.table=table;
       this.cursor = con.cursor();
   }

   iter Get():Row{
    this.cursor.query(this.compileSql());

        var res:Row = this.cursor.fetchone();
        while(res!=nil){
            yield res;
            res = this.cursor.fetchone();
        }

    //yield this.cursor.fetchone();     
   }

   proc getOneAsRecord(ref obj:?eltType):eltType{
       //writeln(this.toSql());
        //this.cursor.query(this.compileSql());
        if(this.cursor.fetchAsRecord(obj) != nil){
            return obj;
        }
        return nil;
   }

   proc Query(){
        this.cursor.query(this.compileSql());
       return this;
   }

   proc QueryAndGetCursor():Cursor{
       return this.cursor;
   }

   proc Exec(){
       this.cursor.execute(this.compileSql());
   }
   /*proc GetAsArray(){
      var data:[{1..0}]Row;
      this.cursor.query(this.toSql());
      for row in this.cursor.fetchall(){
          data.push_back(row);
      }

    return data;
   }*/

    proc toSql():string{
        //this.compileSql();
        return this.sql;
    }
   proc compileSql():string{
       if(this._has("select")){
           this._operation_type="select";
           this._compileSelect();
           //return this.sql;
       }else if(this._has("insert")){
           this._operation_type="insert";
           this._compileInsert();
           //return this.sql;
       }else if(this._has("update")){
           this._operation_type="update";
           this._compileUpdate();
           //return this.sql;
       }else if(this._has("delete")){
           this._operation_type="delete";
           this._compileDelete();
          /// return this.sql;
       }/*else if(this._has("where")){
           this._operation_type="where";
           this._compileWhere();
           return this.sql;
       }*/
       else{
       }
       return this.sql;
   }

   proc clear(){
        this.sql="";
        this._statements_dim.clear();
        this.From(this.table); 
   }

    proc Count():int{
        var col = "COUNT(*) AS count_all";
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row["count_all"]:int; 
    }
    proc Count(colname:string){
        var alias_colname = colname.replace(".","_");
        var col = "COUNT("+this.__quote_columns(colname)+") AS count_"+alias_colname;
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row["count_"+alias_colname]:int;
    }

    proc Max(colname:string):real{ 
        var alias_colname = colname.replace(".","_");
        var prefix="max_";
        var col = "MAX("+this.__quote_columns(colname)+") AS "+prefix+alias_colname;
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row[prefix+alias_colname]:real;
    }

    proc Min(colname:string):real{ 
        var alias_colname = colname.replace(".","_");
        var prefix="min_";
        var col = "MIN("+this.__quote_columns(colname)+") AS "+prefix+alias_colname;
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row[prefix+alias_colname]:real;
    }
    proc Avg(colname:string):real{ 
        var alias_colname = colname.replace(".","_");
        var prefix="avg_";
        var col = "AVG("+this.__quote_columns(colname)+") AS "+prefix+alias_colname;
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row[prefix+alias_colname]:real;
    }

    proc Insert(data:[?D]string, exclude_column:string="id"){
        if(D.member(exclude_column)){
            D.remove(exclude_column);
        }
        this.cursor.insert(this.table,data);
        return this;
    }
    proc Insert(ref data:?eltType, exclude_column:string="id"){
        //this.cursor.insert(this.table,cdoObjToArray(data));
        return this.Insert(cdoObjToArray(data),exclude_column);
    }
    
    proc Update( data:[?D]string, cond_column:string, id:string){
        var col = this.__quote_columns(cond_column);
        var val = this.__quote_values(id);
        this.cursor.update(this.table, col+" = "+val, data);

        return this;
    }

    proc Update(ref data:?eltType, cond_column:string, id:string){
        return this.Update(cdoObjToArray(data),cond_column,id);
    }

    /*proc BelongsTo(data:[?D]string, table:string, local_key:string, foreign_key:string = "id"){
        var qb = this.conn.table(table);
        return qb.Select().Where(foreign_key, data[local_key]); 
    }
    proc BelongsTo(obj:?eltType, table:string, local_key:string, foreign_key:string = "id"){
        var qb = this.conn.table(table);
        var data = cdoObjToArray(obj);
        return qb.Select().Where(foreign_key, data[local_key]); 
    }*/

   proc __arrayToString(arr, delimiter:string=", "):string{
        return delimiter.join(arr);
    }

    proc __quote_columns(colname:string):string{
        if(colname=="*"){
            return "*";
        }
        if(colname.find(".")>0){
            var parts = colname.split(".");
            var last_idx = parts.domain.last;
            parts[last_idx] = this.__quote_columns(parts[last_idx]);
            return ".".join(parts);
        }
        return "\""+colname+"\"";
    }
    proc __quote_values(value:string):string{
        return "'"+value+"'";
    }

    proc __contaisAggregateFunctions(code):bool{
        var aggegates:[{1..0}]string;
            aggegates.push_back("COUNT");
            aggegates.push_back("MAX");
            aggegates.push_back("MIN");
            aggegates.push_back("AVG");
            aggegates.push_back("SUM");
        
        for f in aggegates{

            if(code.find(f)>0){
                return true;
            }
        }
        return false;
    }
    proc __preprocessColumnAlias(code):string{

        if(code.find(" AS ")>0){
            var chunk:[1..0]string;
            var i = 0;
            for part in code.split(" AS "){
                  if(i == 0){
                      //writeln("column: ",part," Contains "+this.__contaisAggregateFunctions(part));
                      if(this.__contaisAggregateFunctions(part)){
                          chunk.push_back(part);
                      }else{
                          chunk.push_back(this.__quote_columns(part));
                      }
                  }else{
                      chunk.push_back(this.__quote_columns(part));
                  }
                  i += 1;
            }
            return " AS ".join(chunk); 
        }

        return this.__quote_columns(code);
    }
   proc _compileSelect(){

       this.sql +="SELECT ";
       var dados = this._get("select").getData();
       for col in dados{
           col = this.__preprocessColumnAlias(col);
       }

       var cols = this.__arrayToString(dados);

       this.sql += cols;
        if(this._has("table")){
            var table = this._get("table");
            this.sql += " FROM "+table[1]+" ";
        }
        if(this._has("join")){
            this._compileJoin();
        }
        if(this._has("where")){
            this._compileWhere();
        }
        if(this._has("orderByAsc")){
            this._compileOrderByAsc();
        }
        if(this._has("orderByDesc")){
            this._compileOrderByDesc();
        }
        if(this._has("groupBy")){
            this._compileGroupBy();
        }
        if(this._has("limit")){
            this._compileLimit();
        }
        if(this._has("offset")){
            this._compileOffset();
        }
   }//end 
   proc _compileWhere(){
       if(this._has("where")){
          var wopcodes =  this._get("where").getWhereData();
          var i:int = 0;
            this.sql += " WHERE ";
            try{
                for op in wopcodes{
                    if(i == 0){
                        if(op[2]=="IN"||op[2]=="NOT IN"){
                            
                            this.sql += " (%s %s %s) ".format(this.__quote_columns(op[1]),op[2],this.__quote_values(op[3]));
                        }else{
                            this.sql += " (%s %s %s) ".format(this.__quote_columns(op[1]),op[2], this.__quote_values(op[3]));
                        }
                    }else{
                        if(op[2] == "IN"||op[2]=="NOT IN"){

                        }else{
                            
                        }
                        this.sql += " %s (%s %s %s) ".format(op[4], this.__quote_columns(op[1]), op[2], this.__quote_values(op[3]));
                    }
                    i += 1;
                }
            }catch{
                writeln("Error where");
            }
        }
        

   }//end

   proc _compileJoin(){
       if(this._has("join")){
          var wopcodes =  this._get("join").getWhereData();
          var i:int = 0;
            
            try{
                for op in wopcodes{                    
                    this.sql += " %s JOIN %s ".format(op[5],op[1]);
                    this.sql += " ON %s %s %s ".format(this.__quote_columns(op[2]),op[3],this.__quote_columns(op[4]));
                }            
            }catch{
                writeln("Error where");
            }
       }    
   }//end

    proc _compileOrderByAsc(){

        if(!this._orderby_declared){
            this.sql += " ORDER BY ";
            this._orderby_declared = true;
        }else{
           this.sql += ", ";
 
        }

        if(this._has("orderByAsc")){
            try{
            var columns =  this._get("orderByAsc").getData();
            
            this.sql += " "+(", ".join(columns));
            }catch{
                writeln("Error order by asc");
            }
        }
    }

    proc _compileOrderByDesc(){
        if(!this._orderby_declared){
            this.sql += " ORDER BY ";
            this._orderby_declared=true;
        }else{
            this.sql += ", ";
        }

        if(this._has("orderByDesc")){
            try{
            var columns =  this._get("orderByDesc").getData();
            this.sql += (" DESC, ".join(columns))+" DESC ";
            }catch{
                writeln("Error order by desc");
            }
        }
    }
    proc _compileGroupBy(){
        if(this._has("groupBy")){
            try{
                var columns =  this._get("groupBy").getData();
                this.sql += " GROUP BY "+(",".join(columns))+" ";
            }catch{
                writeln("Error order by desc");
            }
        }
    }//end

    proc _compileLimit(){
        if(this._has("limit")){
            try{
                var value =  this._get("limit").getData();
                this.sql += " LIMIT "+value[1]+" ";
            }catch{
                writeln("Error LIMIT");
            }
        }
    }

    proc _compileOffset(){
        if(this._has("offset")){
            try{
                var value =  this._get("offset").getData();
                this.sql += " OFFSET "+value[1]+" ";
            }catch{
                writeln("Error offset");
            }
        }
    }//end

    proc _compileInsert(){

    }//end
    proc _compileUpdate(){

    }//end
    proc _compileDelete(){

        if (this._has("delete")) {

            this.sql = "DELETE FROM "+this.table+" ";
            if (this._has("delete")) {
                this._compileWhere();
            }
        }
    }//end

}




module PostgresNative{
extern const CONNECTION_OK:int(64);   

extern const PGRES_TUPLES_OK:int(64);

extern const PGRES_EMPTY_QUERY:int(64);
extern const PGRES_COMMAND_OK:int(64);
extern const PGRES_COPY_OUT:int(64);
extern const PGRES_COPY_IN:int(64);
extern const PGRES_BAD_RESPONSE:int(64);
extern const PGRES_NONFATAL_ERROR:int(64);
extern const PGRES_FATAL_ERROR:int(64);
extern const PGRES_COPY_BOTH:int(64);

extern record FILE{

}

extern type Oid = c_int;
extern record pg_int64{
}

extern const ConnStatusType:int(64);

extern const PostgresPollingStatusType:int(64);

extern const ExecStatusType:int(64);

extern const PGTransactionStatusType:int(64);

extern record PGVerbosity{
}

extern record PGPing{
}

extern record PGconn{
}

extern record PGresult{
}

extern record PGcancel{
}

extern record PGnotify{
}

extern record PQnoticeReceiver{
}

extern record PQnoticeProcessor{
}

extern record pqbool{
}

extern record PQprintOpt{
}

extern record PQconninfoOption{
}

extern record PQArgBlock{
}

extern record PGresAttDesc{
}

extern proc  PQconnectStart(conninfo: c_string ):c_ptr(PGconn );
extern proc  PQconnectStartParams(keywords: c_string, values: c_string, expand_dbname: c_int ):c_ptr(PGconn );
extern proc  PQconnectPoll(conn: c_ptr(PGconn ) ):PostgresPollingStatusType;
extern proc  PQconnectdb(conninfo: c_string ):c_ptr(PGconn );
extern proc  PQconnectdbParams(keywords: c_string, values: c_string, expand_dbname: c_int ):c_ptr(PGconn );
extern proc  PQsetdbLogin(pghost: c_string, pgport: c_string, pgoptions: c_string, pgtty: c_string, dbName: c_string, login: c_string, pwd: c_string ):c_ptr(PGconn );
extern proc  PQfinish(conn: c_ptr(PGconn ) ):c_void_ptr;
extern proc  PQconndefaults():c_ptr(PQconninfoOption );
extern proc  PQconninfoParse(conninfo: c_string, errmsg: c_ptr(c_char ) ):c_ptr(PQconninfoOption );
extern proc  PQconninfo(conn: c_ptr(PGconn ) ):c_ptr(PQconninfoOption );
extern proc  PQconninfoFree(connOptions: c_ptr(PQconninfoOption ) ):c_void_ptr;
extern proc  PQresetStart(conn: c_ptr(PGconn ) ):c_int;
extern proc  PQresetPoll(conn: c_ptr(PGconn ) ):PostgresPollingStatusType;
extern proc  PQreset(conn: c_ptr(PGconn ) ):c_void_ptr;
extern proc  PQgetCancel(conn: c_ptr(PGconn ) ):c_ptr(PGcancel );
extern proc  PQfreeCancel(cancel: c_ptr(PGcancel ) ):c_void_ptr;
extern proc  PQcancel(cancel: c_ptr(PGcancel ), errbuf: c_ptr(c_char), errbufsize: c_int ):c_int;
extern proc  PQrequestCancel(conn: c_ptr(PGconn ) ):c_int;
extern proc  PQdb(conn: c_ptr( PGconn ) ):c_ptr(c_char);
extern proc  PQuser(conn: c_ptr( PGconn ) ):c_ptr(c_char);
extern proc  PQpass(conn: c_ptr( PGconn ) ):c_ptr(c_char);
extern proc  PQhost(conn: c_ptr( PGconn ) ):c_ptr(c_char);
extern proc  PQport(conn: c_ptr( PGconn ) ):c_ptr(c_char);
extern proc  PQtty(conn: c_ptr( PGconn ) ):c_ptr(c_char);
extern proc  PQoptions(conn: c_ptr( PGconn ) ):c_ptr(c_char);
extern proc  PQstatus(conn: c_ptr( PGconn ) ):ConnStatusType;
extern proc  PQtransactionStatus(conn: c_ptr( PGconn ) ):PGTransactionStatusType;
extern proc  PQparameterStatus(conn: c_ptr( PGconn ), paramName: c_string ):c_string;
extern proc  PQprotocolVersion(conn: c_ptr( PGconn ) ):c_int;
extern proc  PQserverVersion(conn: c_ptr( PGconn ) ):c_int;
extern proc  PQerrorMessage(conn: c_ptr( PGconn ) ):c_ptr(c_char);
extern proc  PQsocket(conn: c_ptr( PGconn ) ):c_int;
extern proc  PQbackendPID(conn: c_ptr( PGconn ) ):c_int;
extern proc  PQconnectionNeedsPassword(conn: c_ptr( PGconn ) ):c_int;
extern proc  PQconnectionUsedPassword(conn: c_ptr( PGconn ) ):c_int;
extern proc  PQclientEncoding(conn: c_ptr( PGconn ) ):c_int;
extern proc  PQsetClientEncoding(conn: c_ptr(PGconn ), encoding: c_string ):c_int;
extern proc  PQsslInUse(conn: c_ptr(PGconn ) ):c_int;
extern proc  PQsslStruct(conn: c_ptr(PGconn ), struct_name: c_string ):c_void_ptr;
extern proc  PQsslAttribute(conn: c_ptr(PGconn ), attribute_name: c_string ):c_string;
extern proc  PQsslAttributeNames(conn: c_ptr(PGconn ) ):c_string;
extern proc  PQgetssl(conn: c_ptr(PGconn ) ):c_void_ptr;
extern proc  PQinitSSL(do_init: c_int ):c_void_ptr;
extern proc  PQinitOpenSSL(do_ssl: c_int, do_crypto: c_int ):c_void_ptr;
extern proc  PQsetErrorVerbosity(conn: c_ptr(PGconn ), verbosity: PGVerbosity ):PGVerbosity;
extern proc  PQtrace(conn: c_ptr(PGconn ), debug_port: c_ptr(FILE ) ):c_void_ptr;
extern proc  PQuntrace(conn: c_ptr(PGconn ) ):c_void_ptr;
extern proc  PQsetNoticeReceiver(conn: c_ptr(PGconn ), _proc: PQnoticeReceiver, arg: c_void_ptr ):PQnoticeReceiver;
extern proc  PQsetNoticeProcessor(conn: c_ptr(PGconn ), _proc: PQnoticeProcessor, arg: c_void_ptr ):PQnoticeProcessor;
extern record pgthreadlock_t{
}

extern proc  PQregisterThreadLock(newhandler: pgthreadlock_t ):pgthreadlock_t;
extern proc  PQexec(conn: c_ptr(PGconn ), query: c_string ):c_ptr(PGresult );
extern proc  PQexecParams(conn: c_ptr(PGconn ), command: c_string, nParams: c_int, paramTypes: c_ptr( Oid ), paramValues: c_string, paramLengths: c_ptr( int ), paramFormats: c_ptr( int ), resultFormat: c_int ):c_ptr(PGresult );
extern proc  PQprepare(conn: c_ptr(PGconn ), stmtName: c_string, query: c_string, nParams: c_int, paramTypes: c_ptr( Oid ) ):c_ptr(PGresult );
extern proc  PQexecPrepared(conn: c_ptr(PGconn ), stmtName: c_string, nParams: c_int, paramValues: c_string, paramLengths: c_ptr( int ), paramFormats: c_ptr( int ), resultFormat: c_int ):c_ptr(PGresult );
extern proc  PQsendQuery(conn: c_ptr(PGconn ), query: c_string ):c_int;
extern proc  PQsendQueryParams(conn: c_ptr(PGconn ), command: c_string, nParams: c_int, paramTypes: c_ptr( Oid ), paramValues: c_string, paramLengths: c_ptr( int ), paramFormats: c_ptr( int ), resultFormat: c_int ):c_int;
extern proc  PQsendPrepare(conn: c_ptr(PGconn ), stmtName: c_string, query: c_string, nParams: c_int, paramTypes: c_ptr( Oid ) ):c_int;
extern proc  PQsendQueryPrepared(conn: c_ptr(PGconn ), stmtName: c_string, nParams: c_int, paramValues: c_string, paramLengths: c_ptr( int ), paramFormats: c_ptr( int ), resultFormat: c_int ):c_int;
extern proc  PQsetSingleRowMode(conn: c_ptr(PGconn ) ):c_int;
extern proc  PQgetResult(conn: c_ptr(PGconn ) ):c_ptr(PGresult );
extern proc  PQisBusy(conn: c_ptr(PGconn ) ):c_int;
extern proc  PQconsumeInput(conn: c_ptr(PGconn ) ):c_int;
extern proc  PQnotifies(conn: c_ptr(PGconn ) ):c_ptr(PGnotify );
extern proc  PQputCopyData(conn: c_ptr(PGconn ), buffer: c_string, nbytes: c_int ):c_int;
extern proc  PQputCopyEnd(conn: c_ptr(PGconn ), errormsg: c_string ):c_int;
extern proc  PQgetCopyData(conn: c_ptr(PGconn ), buffer: c_ptr(c_char ), async: c_int ):c_int;
extern proc  PQgetline(conn: c_ptr(PGconn ),_string: c_ptr(c_char), length: c_int ):c_int;
extern proc  PQputline(conn: c_ptr(PGconn ),_string: c_string ):c_int;
extern proc  PQgetlineAsync(conn: c_ptr(PGconn ), buffer: c_ptr(c_char), bufsize: c_int ):c_int;
extern proc  PQputnbytes(conn: c_ptr(PGconn ), buffer: c_string, nbytes: c_int ):c_int;
extern proc  PQendcopy(conn: c_ptr(PGconn ) ):c_int;
extern proc  PQsetnonblocking(conn: c_ptr(PGconn ), arg: c_int ):c_int;
extern proc  PQisnonblocking(conn: c_ptr( PGconn ) ):c_int;
extern proc  PQisthreadsafe():c_int;
extern proc  PQping(conninfo: c_string ):PGPing;
extern proc  PQpingParams(keywords: c_string, values: c_string, expand_dbname: c_int ):PGPing;
extern proc  PQflush(conn: c_ptr(PGconn ) ):c_int;
extern proc  PQfn(conn: c_ptr(PGconn ), fnid: c_int, result_buf: c_ptr(c_int), result_len: c_ptr(c_int), result_is_int: c_int, args: c_ptr( PQArgBlock ), nargs: c_int ):c_ptr(PGresult );
extern proc  PQresultStatus(res: c_ptr( PGresult ) ):ExecStatusType;
extern proc  PQresStatus(status: ExecStatusType ):c_ptr(c_char);
extern proc  PQresultErrorMessage(res: c_ptr( PGresult ) ):c_ptr(c_char);
extern proc  PQresultErrorField(res: c_ptr( PGresult ), fieldcode: c_int ):c_ptr(c_char);
extern proc  PQntuples(res: c_ptr( PGresult ) ):c_int;
extern proc  PQnfields(res: c_ptr( PGresult ) ):c_int;
extern proc  PQbinaryTuples(res: c_ptr( PGresult ) ):c_int;
extern proc  PQfname(res: c_ptr( PGresult ), field_num: c_int ):c_string;//c_ptr(c_char);
extern proc  PQfnumber(res: c_ptr( PGresult ), field_name: c_string ):c_int;
extern proc  PQftable(res: c_ptr( PGresult ), field_num: c_int ):Oid;
extern proc  PQftablecol(res: c_ptr( PGresult ), field_num: c_int ):c_int;
extern proc  PQfformat(res: c_ptr( PGresult ), field_num: c_int ):c_int;
extern proc  PQftype(res: c_ptr( PGresult ), field_num: c_int ):Oid;
extern proc  PQfsize(res: c_ptr( PGresult ), field_num: c_int ):c_int;
extern proc  PQfmod(res: c_ptr( PGresult ), field_num: c_int ):c_int;
extern proc  PQcmdStatus(res: c_ptr(PGresult ) ):c_ptr(c_char);
extern proc  PQoidStatus(res: c_ptr( PGresult ) ):c_ptr(c_char);
extern proc  PQoidValue(res: c_ptr( PGresult ) ):Oid;
extern proc  PQcmdTuples(res: c_ptr(PGresult ) ):c_ptr(c_char);
extern proc  PQgetvalue(res: c_ptr( PGresult ), tup_num: c_int, field_num: c_int ):c_ptr(c_char);
extern proc  PQgetlength(res: c_ptr( PGresult ), tup_num: c_int, field_num: c_int ):c_int;
extern proc  PQgetisnull(res: c_ptr( PGresult ), tup_num: c_int, field_num: c_int ):c_int;
extern proc  PQnparams(res: c_ptr( PGresult ) ):c_int;
extern proc  PQparamtype(res: c_ptr( PGresult ), param_num: c_int ):Oid;
extern proc  PQdescribePrepared(conn: c_ptr(PGconn ), stmt: c_string ):c_ptr(PGresult );
extern proc  PQdescribePortal(conn: c_ptr(PGconn ), portal: c_string ):c_ptr(PGresult );
extern proc  PQsendDescribePrepared(conn: c_ptr(PGconn ), stmt: c_string ):c_int;
extern proc  PQsendDescribePortal(conn: c_ptr(PGconn ), portal: c_string ):c_int;
extern proc  PQclear(res: c_ptr(PGresult ) ):c_void_ptr;
extern proc  PQfreemem(ptr: c_void_ptr ):c_void_ptr;
extern proc  PQmakeEmptyPGresult(conn: c_ptr(PGconn ), status: ExecStatusType ):c_ptr(PGresult );
extern proc  PQcopyResult(src: c_ptr( PGresult ), flags: c_int ):c_ptr(PGresult );
extern proc  PQsetResultAttrs(res: c_ptr(PGresult ), numAttributes: c_int, attDescs: c_ptr(PGresAttDesc ) ):c_int;
extern proc  PQresultAlloc(res: c_ptr(PGresult ), nBytes: c_int ):c_void_ptr;
extern proc  PQsetvalue(res: c_ptr(PGresult ), tup_num: c_int, field_num: c_int, value: c_ptr(c_char), len: c_int ):c_int;
extern proc  PQescapeStringConn():c_int;
extern proc  PQescapeLiteral(conn: c_ptr(PGconn ), str: c_string, len: c_int ):c_ptr(c_char);
extern proc  PQescapeIdentifier(conn: c_ptr(PGconn ), str: c_string, len: c_int ):c_ptr(c_char);
extern proc  PQescapeByteaConn(conn: c_ptr(PGconn ), from: c_ptr( c_uchar), from_length: c_int, to_length: c_ptr(c_int) ):c_ptr(c_uchar);
extern proc  PQunescapeBytea(strtext: c_ptr( c_uchar), retbuflen: c_ptr(c_int) ):c_ptr(c_uchar);
extern proc  PQescapeString():c_int;
extern proc  PQescapeBytea(from: c_ptr( c_uchar), from_length: c_int, to_length: c_ptr(c_int) ):c_ptr(c_uchar);
extern proc  PQprint(fout: c_ptr(FILE ), res: c_ptr( PGresult ), ps: c_ptr( PQprintOpt ) ):c_void_ptr;
extern proc  PQdisplayTuples(res: c_ptr( PGresult ), fp: c_ptr(FILE ), fillAlign: c_int, fieldSep: c_string, printHeader: c_int, quiet: c_int ):c_void_ptr;
extern proc  PQprintTuples(res: c_ptr( PGresult ), fout: c_ptr(FILE ), printAttName: c_int, terseOutput: c_int, width: c_int ):c_void_ptr;
extern proc  lo_open(conn: c_ptr(PGconn ), lobjId: Oid, mode: c_int ):c_int;
extern proc  lo_close(conn: c_ptr(PGconn ), fd: c_int ):c_int;
extern proc  lo_read(conn: c_ptr(PGconn ), fd: c_int, buf: c_ptr(c_char), len: c_int ):c_int;
extern proc  lo_write(conn: c_ptr(PGconn ), fd: c_int, buf: c_string, len: c_int ):c_int;
extern proc  lo_lseek(conn: c_ptr(PGconn ), fd: c_int, offset: c_int, whence: c_int ):c_int;
extern proc  lo_lseek64(conn: c_ptr(PGconn ), fd: c_int, offset: pg_int64, whence: c_int ):pg_int64;
extern proc  lo_creat(conn: c_ptr(PGconn ), mode: c_int ):Oid;
extern proc  lo_create(conn: c_ptr(PGconn ), lobjId: Oid ):Oid;
extern proc  lo_tell(conn: c_ptr(PGconn ), fd: c_int ):c_int;
extern proc  lo_tell64(conn: c_ptr(PGconn ), fd: c_int ):pg_int64;
extern proc  lo_truncate(conn: c_ptr(PGconn ), fd: c_int, len: c_int ):c_int;
extern proc  lo_truncate64(conn: c_ptr(PGconn ), fd: c_int, len: pg_int64 ):c_int;
extern proc  lo_unlink(conn: c_ptr(PGconn ), lobjId: Oid ):c_int;
extern proc  lo_import(conn: c_ptr(PGconn ), filename: c_string ):Oid;
extern proc  lo_import_with_oid(conn: c_ptr(PGconn ), filename: c_string, lobjId: Oid ):Oid;
extern proc  lo_export(conn: c_ptr(PGconn ), lobjId: Oid, filename: c_string ):c_int;
extern proc  PQlibVersion():c_int;
extern proc  PQmblen(s: c_string, encoding: c_int ):c_int;
extern proc  PQdsplen(s: c_string, encoding: c_int ):c_int;
extern proc  PQenv2encoding():c_int;
extern proc  PQencryptPassword(passwd: c_string, user: c_string ):c_ptr(c_char);
extern proc  pg_char_to_encoding(name: c_string ):c_int;
extern proc  pg_encoding_to_char(encoding: c_int ):c_string;
extern proc  pg_valid_server_encoding_id(encoding: c_int ):c_int;
}



}//end module