/*
 * Copyright (C) 2018 Marcos Cleison Silva Santana
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
module CDOQueryBuilderPostgres{
use Cdo;
use Postgres;
use CDOModelEngine;
use CDOQueryBuilder;


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
        try{
        var col = "COUNT(*) AS count_all";
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row["count_all"]:int;
        }catch{
            writeln("Error:[proc Count], Cannot convert value or grab it.");
            return -1;
        } 
    }
    proc Count(colname:string){
        try{
        var alias_colname = colname.replace(".","_");
        var col = "COUNT("+this.__quote_columns(colname)+") AS count_"+alias_colname;
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row["count_"+alias_colname]:int;
        }catch{
            writeln("Error:[proc Count], Cannot convert value or grab it.");
            return -1;
        }
    }

    proc Max(colname:string):real{ 
        try{
        var alias_colname = colname.replace(".","_");
        var prefix="max_";
        var col = "MAX("+this.__quote_columns(colname)+") AS "+prefix+alias_colname;
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row[prefix+alias_colname]:real;
        }catch{
            writeln("Error:[proc Max], Cannot convert value or grab it.");
            return 0.0;
        }
    }

    proc Min(colname:string):real{ 
        try{
        var alias_colname = colname.replace(".","_");
        var prefix="min_";
        var col = "MIN("+this.__quote_columns(colname)+") AS "+prefix+alias_colname;
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row[prefix+alias_colname]:real;
        }catch{
            writeln("Error:[proc Min], Cannot convert value or grab it.");
            return 0.0;
        }
    }
    proc Avg(colname:string):real{ 
        try{
        var alias_colname = colname.replace(".","_");
        var prefix="avg_";
        var col = "AVG("+this.__quote_columns(colname)+") AS "+prefix+alias_colname;
        this.Select([col]);
        this.cursor.query(this.compileSql());
        var row = this.cursor.fetchone();
        return row[prefix+alias_colname]:real;
        }catch{
            writeln("Error:[proc Avg], Cannot convert value or grab it.");
            return 0.0;
        }
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


}