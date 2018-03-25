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
module CDOQueryBuilder{
use Cdo;

class QueryBuilder{
    forwarding var query_driver: QueryBuilderBase;
}


type whereType = 6*string;

class StatementData{
    var op:string;
    var data_dim:domain(1);
    var data:[data_dim]string;

    var where_data_dim:domain(1);
    var where_data:[where_data_dim]whereType;

    proc StatementData(op, data){
        this.op = op;
        this.data.push_back(data);
    }

    proc StatementData(op:string, data:whereType){
        this.where_data.push_back(data);
        this.op=op;
    }
    
    proc this(i:int):string{
        try{
            if(this.op=="where"){
                return this.where_data[i];
            }else{
                return this.data[i];
            }
        }catch{
            writeln("Error Statement Data");
        }
        return "";
    }

    iter these()ref:string{
        try{
            if(this.op=="where"){
                for obj in this.where_data{
                    yield obj;
                }
            }else{
                for obj in this.data{
                    yield obj;
                }
            }
        }catch{
            writeln("Error Statement Data");
        }
    }

    proc append(data:string){
        this.data.push_back(data);
    }
    proc append(data:[?D]string){
        this.data.push_back(data);
    }
    proc append(data:whereType){
        this.where_data.push_back(data);
    }

    proc setData(data){
        this.data=data;
    }
    proc getData(){
        return this.data;
    }
    proc getWhereData(){
        return this.where_data;
    }
    
    proc writeThis(f){
        try{
            if(this.op=="where"){
                for c in this.where_data{
                    f.writeln("Op:",this.op," *data=",c);
                }
            }else{
                for c in this.data{
                    f.writeln("Op:",this.op," data=",c);
                }
            }
        }catch{
            writeln("Error on write");
        }
    }
}





class QueryBuilderBase{

    var _where_cond_dim:domain(1);
    var _where_cond:[_where_cond_dim]whereType;

    var _column_names_dom: domain(1);
    var _column_names: [_column_names_dom]string;

    var table:string = "";
    var con:Connection;

    var _optype_dim:domain(1);
    var _optype:[_optype_dim]string;

    var _statements_dim:domain(string);
    var _statements:[_statements_dim]StatementData;

    var sql="";


    proc QueryBuilderBase(){

    }


    proc _addStatement(key,value){
        this._statements[key] = value;
    }

    proc Select(){

        if(this._statements_dim.member("select")){
            var stdata = this._statements["select"];
            stdata.append("*");
        }else{
            this._statements["select"] = new StatementData("select",["*"]);
        }
        return this;
    }
    proc Select(columns:[?D]string){
        if(this._statements_dim.member("select")){
            var stdata = this._statements["select"];
            stdata.append(columns);
        }else{
            this._statements["select"] = new StatementData("select",columns);
        }
        return this;
    }


    proc From(table){
        if(this._statements_dim.member("from")){
            var stdata = this._statements["from"];
            stdata.append(table);
        }else{
            this._statements["table"] = new StatementData("table",[table]);
        }
        return this;
    }

    proc Where(column:string, value){
        return this.Where(column,"=",value,"AND");
    }

    proc Where(column:string, op:string, value, concat_op="AND"){

        var ops:whereType = (column ,op, value,concat_op,"","");
       
        if(this._statements_dim.member("where")){
            var stdata = this._statements["where"];
            stdata.append(ops);
        }else{
            this._statements["where"] = new StatementData("where",ops);
        }
        return this;
    }
    proc WhereIn(column:string, values:[?D]string ,concat_op="AND"){ 
        var value = "("+(" ,".join(values))+")";
        return this.Where(column,"IN",value,concat_op);
    }
    proc WhereNotIn( column:string, values:[?D]string, value,concat_op="AND"){
        var value = "("+(" ,".join(values))+")";

        return this.Where(column,"NOT IN",value,concat_op);
    }

    proc WhereNotNull( column:string,concat_op="AND"){
        return this.Where(column,"IS NOT NULL"," ",concat_op);
    }

    proc WhereBetween( column:string, low_bound:string, upper_bound:string, concat_op="AND"){
        var value = low_bound+" AND "+upper_bound;
        return this.Where(column,"BETWEEN",value,concat_op);
    }

    proc WhereNotBetween( column:string, low_bound:string, upper_bound:string, concat_op="AND"){
        var value = low_bound+" AND "+upper_bound;
        return this.Where(column,"NOT BETWEEN",value,concat_op);
    }

    proc orWhere( column:string, value){
        return this.Where( column, "=", value, "OR");
    }

    
    proc orWhere( column:string, op:string, value){
        return this.Where( column, op, value, "OR");
    }
    
    proc orWhereIn(column:string, values:[?D]string){
        return this.WhereIn(column,values,"OR");
    }
    
    proc orWhereNotIn(column:string, values:[?D]string ){
        return this.WhereNotIn(column,values,"OR");
    }

    proc orWhereBetween( column:string, low_bound:string, upper_bound:string){
        return this.WhereBetween(column,low_bound, upper_bound,"OR");
    }
    proc orWhereNotBetween(column:string, low_bound:string, upper_bound:string){
        return this.WhereNotBetween(column,low_bound, upper_bound,"OR");
    }

    proc Join(table:string, column1:string, op:string, column2:string, join_type:string="INNER" ,concat_op="AND"){
        
        var ops:whereType = (table, column1 , op, column2, join_type,concat_op);
       
        if(this._statements_dim.member("join")){
            var stdata = this._statements["join"];
            stdata.append(ops);
        }else{
            this._statements["join"] = new StatementData("join",ops);
        }

        return this;
    }

    proc Join(table:string, column1:string,op:string, column2:string){
        return this.Join(table, column1, op, column2, "INNER", "AND");
    }

    proc Join(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "INNER", "AND");
    }

    proc innerJoin(table:string, column1:string, op:string, column2:string){
        return this.Join(table, column1, op, column2, "INNER", "AND");
    }

    proc innerJoin(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "INNER", "AND");
    }

    proc leftJoin(table:string, column1:string,op:string, column2:string){
        return this.Join(table, column1, op, column2, "LEFT", "AND");
    }

    proc leftJoin(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "LEFT", "AND");
    }

    proc rightJoin(table:string, column1:string,op:string, column2:string){
        return this.Join(table, column1, op, column2, "RIGHT", "AND");
    }
    proc rightJoin(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "RIGHT", "AND");
    }
    proc fullJoin(table:string, column1:string,op:string, column2:string){
        return this.Join(table, column1, op, column2, "RIGHT", "AND");
    }
    proc fullJoin(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "RIGHT", "AND");
    }
    proc Insert(data:[?D]string, exclude_column:string="id"){
        return this;
    }
    proc Insert(ref data:?eltType, exclude_column:string="id"){
        return this;
    }

    proc Update( data:[?D]string, cond_column:string, id:string){
        return this;
    }

    proc Update(ref data:?eltType, cond_column:string, id:string){
        return this;
    }

    proc Delete(){
        
        if(this._statements_dim.member("delete")){
            var stdata = this._statements["delete"];
            stdata.append("*");
        }else{
            this._statements["delete"] = new StatementData("delete",["*"]);
        }
        
        return this;
    }
    proc Delete(column:string,value:string){
        this.Delete().Where(column,value).Exec();
    }
   /* proc BelongsTo(data:[?D]string, table:string, local_key:string, foreign_key:string = "id"){
        return nil;
    }
    proc BelongsTo(obj:?altType, table:string, local_key:string, foreign_key:string = "id"){
        return nil;
    }*/




    proc OrderBy(column){
        if(this._statements_dim.member("orderByAsc")){
            var stdata = this._statements["orderByAsc"];
            stdata.append(column);
        }else{
            this._statements["orderByAsc"] = new StatementData("orderByAsc",column);
        }
        return this;
    }
    proc OrderBy(columns:[?D]string){
        if(this._statements_dim.member("orderByAsc")){
            var stdata = this._statements["orderByAsc"];
            stdata.append(columns);
        }else{
            this._statements["orderByAsc"] = new StatementData("orderByAsc",columns);
        }
        return this;
    }

    proc OrderByDesc(column){
        if(this._statements_dim.member("orderByDesc")){
            var stdata = this._statements["orderByDesc"];
            stdata.append(column);
        }else{
            this._statements["orderByDesc"] = new StatementData("orderByDesc",column);
        }
        
        return this;
    }

    proc OrderByDesc(columns:[?D]string){
        if(this._statements_dim.member("orderByDesc")){
            var stdata = this._statements["orderByDesc"];
            stdata.append(columns);
        }else{
            this._statements["orderByDesc"] = new StatementData("orderByDesc",columns);
        }
        return this;
    }
    proc GroupBy(column){
        if(this._statements_dim.member("groupBy")){
            var stdata = this._statements["groupBy"];
            stdata.append(column);
        }else{
            this._statements["groupBy"] = new StatementData("groupBy",column);
        }

        return this;
    }

    proc GroupBy(columns:[?D]string){
        if(this._statements_dim.member("groupBy")){
            var stdata = this._statements["groupBy"];
            stdata.append(columns);
        }else{
            this._statements["groupBy"] = new StatementData("groupBy",columns);
        }
        return this;
    }
    proc Limit(i:int){
        if(this._statements_dim.member("limit")){
            var stdata = this._statements["limit"];
            stdata.setData([i:string]);
        }else{
            this._statements["limit"] = new StatementData("limit",[i:string]);
        }   
        return this;
    }
    proc Offset(i:int){
        if(this._statements_dim.member("offset")){
            var stdata = this._statements["offset"];
            stdata.setData([i:string]);
        }else{
            this._statements["offset"] = new StatementData("offset",[i:string]);
        }
        return this;
    }

    proc toSql():string{
        return "";
    }

    proc Count():int{ 
         return 0;
    }
    proc Count(colname:string):int{ 
         return 0;
    }
    proc Max(colname:string):real{ 
         return 0;
    }
    proc Min(colname:string):real{ 
         return 0;
    }

    proc Avg(colname:string):real{ 
         return 0;
    }

    iter Get():Row{
        
    }
    proc getOneAsRecord(ref obj:?eltType):eltType{
       return nil;
    }
    
   proc Query(){
    return this;
   }

    proc Exec(){
        
    }
    proc QueryAndGetCursor():Cursor{
       return nil;
   }


    proc clear(){
        this.sql="";
        this._statements_dim.clear();
    }
    

    proc writeThis(f){
        try{
            for c in this._statements{
                f.writeln(c);
            }
        }catch{
            writeln("Error on write");
        }
    }

    proc _has(opname:string):bool{
        return this._statements_dim.member(opname);
    }

    proc _get(opname):StatementData{
        return this._statements[opname];
    }



}



}