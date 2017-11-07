/*
 * Copyright (C) 2017 Marcos Cleison Silva Santana
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
module Sqlite{
    use Cdo;
    use SysBasic;
	use SqliteNative;
    require "sqlite3.h","-lsqlite3";



proc SqliteConnectionFactory( database:string=""):Connection{

  return new Connection(new SqliteConnection(database));
}

class SqliteConnection:ConnectionBase{

     var dsn:string;
     var conn:c_ptr(sqlite3);

     proc SqliteConnection(database:string=""){
        try{
            //this.dsn="postgresql://%s:%s@%s/%s".format(user,passwd,host,database);
           // writeln("conecting to ",this.dsn);
            sqlite3_open("teste.db", this.conn);

	        if (this.conn == c_nil)
	        {
		        writeln("Failed to open DB\n");
		        halt("Error");
	        }

        }catch{
                writeln("Postgres Connection to database exception");
        }
         
     }

    proc getNativeConection(): c_ptr(sqlite3){
        return this.conn;    
    }

    proc helloWorld(){
        writeln("Hello from SqliteConnection");
    }

    proc cursor(){
        return new Cursor(new SqliteCursor(this,this.conn));
    }
    proc commit(){

    }
    proc rollback(){

    }
    proc close(){

    }

    proc __registerTypes(){
       /** this.__registerTypeName(20, parseBigInteger); // int8
        this.__registerTypeName(21, parseInteger); // int2
        this.__registerTypeName(23, parseInteger); // int4
        this.__registerTypeName(26, parseInteger); // oid
        this.__registerTypeName(700, parseFloat); // float4/real
        this.__registerTypeName(701, parseFloat); // float8/double
        this.__registerTypeName(16, parseBool);
        this.__registerTypeName(1082, parseDate); // date
        this.__registerTypeName(1114, parseDate); // timestamp without timezone
        this.__registerTypeName(1184, parseDate); // timestamp
        this.__registerTypeName(600, parsePoint); // point
        this.__registerTypeName(651, parseStringArray); // cidr[]
        this.__registerTypeName(718, parseCircle); // circle
        this.__registerTypeName(1000, parseBoolArray);
        this.__registerTypeName(1001, parseByteAArray);
        this.__registerTypeName(1005, parseIntegerArray); // _int2
        this.__registerTypeName(1007, parseIntegerArray); // _int4
        this.__registerTypeName(1028, parseIntegerArray); // oid[]
        this.__registerTypeName(1016, parseBigIntegerArray); // _int8
        this.__registerTypeName(1017, parsePointArray); // point[]
        this.__registerTypeName(1021, parseFloatArray); // _float4
        this.__registerTypeName(1022, parseFloatArray); // _float8
        this.__registerTypeName(1231, parseFloatArray); // _numeric
        this.__registerTypeName(1014, parseStringArray); //char
        this.__registerTypeName(1015, parseStringArray); //varchar
        this.__registerTypeName(1008, parseStringArray);
        this.__registerTypeName(1009, parseStringArray);
        this.__registerTypeName(1040, parseStringArray); // macaddr[]
        this.__registerTypeName(1041, parseStringArray); // inet[]
        this.__registerTypeName(1115, parseDateArray); // timestamp without time zone[]
        this.__registerTypeName(1182, parseDateArray); // _date
        this.__registerTypeName(1185, parseDateArray); // timestamp with time zone[]
        this.__registerTypeName(1186, parseInterval);
        this.__registerTypeName(17, parseByteA);
        this.__registerTypeName(114, JSON.parse.bind(JSON)); // json
        this.__registerTypeName(3802, JSON.parse.bind(JSON)); // jsonb
        this.__registerTypeName(199, parseJsonArray); // json[]
        this.__registerTypeName(3807, parseJsonArray); // jsonb[]
        this.__registerTypeName(3907, parseStringArray); // numrange[]
        this.__registerTypeName(2951, parseStringArray); // uuid[]
        this.__registerTypeName(791, parseStringArray); // money[]
        this.__registerTypeName(1183, parseStringArray); // time[]
        this.__registerTypeName(1270, parseStringArray); // timetz[]
        */
  
    }

}

class SqliteCursor:CursorBase{
    
   var con:SqliteConnection;
   var sqlitecon:c_ptr(sqlite3);
   //var res:c_ptr(PGresult);
   var stmt:c_ptr(sqlite3_stmt);
   
   var nFields:int(32);
   var numRows:int(32);
   var curRow:int(32)=0;

   proc SqliteCursor(con:SqliteConnection, sqlitecon:c_ptr(sqlite3)){
       this.con = con;
       this.sqlitecon=sqlitecon;
   }

    proc rowcount():int(32){
        return this.numRows;
    }


    proc callproc(){

    }

    proc close(){

        sqlite3_finalize(this.stmt);    
    }

    proc execute(query:string, params){
        try{
            this.execute(query.format((...params)));
        }catch{
            writeln("Error");
        }
    }

    proc execute(query:string){
    
        sqlite3_prepare_v2(this.sqlitecon, query.localize().c_str(), -1:c_int, this.stmt, c_nil:c_stringptr);
        this.__removeColumns();
        this.nFields = sqlite3_column_count(this.stmt):int(32);
        var ii:int(32)=0;

        while ( ii < nFields){    
            var colname = new string(sqlite3_column_name(this.stmt, ii:c_int));
            this.__addColumn(ii,colname);
            ii+=1;
        }
        this.numRows = 0;
        this.curRow=0;
    }

    proc query(query:string){
        this.execute(query);
   }

    proc query(query:string, params){
        try{
            this.query(query.format((...params)));
        }catch{
            writeln("Error");
        }
    }

    proc dump(){
    }

    proc executemany(str:string, pr){

        try{

            writeln(str.format((...pr)));

        }catch{
            writeln("Error");
        }
        
        
        //for p in pr{
            //writeln(p);
        //}
    }

    proc fetchrow(idx:int):Row{
       //todo 
        var row = new Row();
       
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
        var retval = sqlite3_step(stmt);

        if(retval == SQLITE_DONE){
           return nil;
        }

       if(retval == SQLITE_ROW){
       var row = new Row();

       var j:int(32)=0;
      
       while(j < this.nFields){
            var datum = "";//new string(PQgetvalue(res, this.curRow:c_int, j:c_int):c_string);
             var col_type = sqlite3_column_type(this.stmt, j:c_int);
             try{
                if(col_type == SQLITE_TEXT){
                    datum = new string(sqlite3_column_text(stmt, j:c_int));
                }else if(col_type == SQLITE_INTEGER){
                    var ivalue = sqlite3_column_int(this.stmt, j);
                    datum="%i".format(ivalue);

                }else if(col_type == SQLITE_FLOAT){
                    var fvalue = sqlite3_column_double(this.stmt, j);
                    datum="%f".format(fvalue);

                }else if(col_type == SQLITE_BLOB){
                    var bvalue = sqlite3_column_blob(this.stmt, j);
                    datum=new string(bvalue);

                }else if(col_type == SQLITE_NULL){
                    datum="null";
                }else{
                    datum="";
                }
             }catch{

                 writeln("Error on fetch");

             }
            var colinfo = this.getColumnInfo(j);
            row.addData(colinfo.name,datum);
            j += 1;
        }
        this.curRow += 1;
        return row;
       }
       return nil;
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
}


   

module SqliteNative{    

extern type char = c_char;
extern type double = c_double;

extern const SQLITE_DONE:c_int;

extern const SQLITE_TEXT:c_int;
extern const SQLITE_INTEGER:c_int;
extern const SQLITE_FLOAT:c_int;
extern const SQLITE_BLOB:c_int;

extern const SQLITE_NULL:c_int;

extern const SQLITE_ROW:c_int;
extern type c_stringptr = c_ptr(c_string);

type sqlite3ptr = c_ptr(sqlite3);

type sqlite3_stmtptr=c_ptr(sqlite3_stmt );

extern proc  sqlite3_libversion():c_string;
extern proc  sqlite3_sourceid():c_string;
extern proc  sqlite3_libversion_number():c_int;
extern proc  sqlite3_compileoption_used(zOptName: c_string ):c_int;
extern proc  sqlite3_compileoption_get(N: c_int ):c_string;
extern proc  sqlite3_threadsafe():c_int;

extern record sqlite3{
}

extern record sqlite_int64{
}

extern record sqlite_uint64{
}

extern record sqlite3_int64{
}

extern record sqlite3_uint64{
}

extern proc  sqlite3_close(args1: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_close_v2(args1: c_ptr(sqlite3 ) ):c_int;
extern record sqlite3_callback{
}

//extern proc  sqlite3_exec(sql: c_string, callback: c_ptr(int ()(void , int, char , char )), args4: c_void_ptr, errmsg: c_ptr(char ) ):c_int;

extern record sqlite3_file{
}


extern record sqlite3_io_methods{
}



extern record sqlite3_mutex{
}


extern record sqlite3_api_routines{
}


extern record sqlite3_vfs{
}

extern record sqlite3_syscall_ptr{
}


extern proc  sqlite3_initialize():c_int;
extern proc  sqlite3_shutdown():c_int;
extern proc  sqlite3_os_init():c_int;
extern proc  sqlite3_os_end():c_int;
extern proc  sqlite3_config(args1: c_int ):c_int;
extern proc  sqlite3_db_config(op: c_int ):c_int;

extern record sqlite3_mem_methods{
}


extern proc  sqlite3_extended_result_codes(onoff: c_int ):c_int;
extern proc  sqlite3_last_insert_rowid(_sqlite3_int64: sqlite3_int64, args2: c_ptr(sqlite3 ) ):sqlite3_int64;
extern proc  sqlite3_set_last_insert_rowid(args2: sqlite3_int64 ):c_void_ptr;
extern proc  sqlite3_changes(args1: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_total_changes(args1: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_interrupt(args1: c_ptr(sqlite3 ) ):c_void_ptr;
extern proc  sqlite3_complete(sql: c_string ):c_int;
extern proc  sqlite3_complete16(sql: c_void_ptr ):c_int;
//extern proc  sqlite3_busy_handler(args2: c_ptr(int ()(void , int)), args3: c_void_ptr ):c_int;
extern proc  sqlite3_busy_timeout(ms: c_int ):c_int;
extern proc  sqlite3_get_table(zSql: c_string, pazResult: c_ptr(char ), pnRow: c_ptr(c_int), pnColumn: c_ptr(c_int), pzErrmsg: c_ptr(char ) ):c_int;
extern proc  sqlite3_free_table(result: c_ptr(char ) ):c_void_ptr;
extern proc  sqlite3_mprintf(args1: c_string ):c_ptr(c_char);
extern proc  sqlite3_vmprintf(va_list: c_int ):c_ptr(c_char);
extern proc  sqlite3_snprintf(args2: c_ptr(c_char), args3: c_string ):c_ptr(c_char);
extern proc  sqlite3_vsnprintf(args2: c_ptr(c_char), args3: c_string, va_list: c_int ):c_ptr(c_char);
extern proc  sqlite3_malloc(args1: c_int ):c_void_ptr;
extern proc  sqlite3_malloc64(args1: sqlite3_uint64 ):c_void_ptr;
extern proc  sqlite3_realloc(args2: c_int ):c_void_ptr;
extern proc  sqlite3_realloc64(args2: sqlite3_uint64 ):c_void_ptr;
extern proc  sqlite3_free(args1: c_void_ptr ):c_void_ptr;
extern proc  sqlite3_msize(_sqlite3_uint64: sqlite3_uint64, args2: c_void_ptr ):sqlite3_uint64;
extern proc  sqlite3_memory_used(_sqlite3_int64: sqlite3_int64 ):sqlite3_int64;
extern proc  sqlite3_memory_highwater(_sqlite3_int64: sqlite3_int64, resetFlag: c_int ):sqlite3_int64;
extern proc  sqlite3_randomness(P: c_void_ptr ):c_void_ptr;
//extern proc  sqlite3_set_authorizer(xAuth: c_ptr(int ()(void , int, const char , const char , const char , const char )), pUserData: c_void_ptr ):c_int;
//extern proc  sqlite3_trace(xTrace: c_ptr(void ()(void , const char )), args3: c_void_ptr ):c_void_ptr;
//extern proc  sqlite3_profile(xProfile: c_ptr(void ()(void , const char , sqlite3_uint64)), args3: c_void_ptr ):c_void_ptr;
//extern proc  sqlite3_trace_v2(uMask: c_uint, xCallback: c_ptr(int ()(unsigned int, void , void , void )), pCtx: c_void_ptr ):c_int;
//extern proc  sqlite3_progress_handler(args2: c_int, args3: c_ptr(int ()(void )), args4: c_void_ptr ):c_void_ptr;
extern proc  sqlite3_open(db:c_string,ref ppDb: sqlite3ptr ):c_int;
extern proc  sqlite3_open16(ppDb: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_open_v2(ppDb: c_ptr(sqlite3 ), flags: c_int, zVfs: c_string ):c_int;
extern proc  sqlite3_uri_parameter(zParam: c_string ):c_string;
extern proc  sqlite3_uri_boolean(zParam: c_string, bDefault: c_int ):c_int;
extern proc  sqlite3_uri_int64(_sqlite3_int64: sqlite3_int64, args2: c_string, args3: c_string, args4: sqlite3_int64 ):sqlite3_int64;
extern proc  sqlite3_errcode(db: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_extended_errcode(db: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_errmsg(args1: c_ptr(sqlite3 ) ):c_string;
extern proc  sqlite3_errmsg16(args1: c_ptr(sqlite3 ) ):c_void_ptr;
extern proc  sqlite3_errstr(args1: c_int ):c_string;


extern record sqlite3_stmt{
}

extern proc  sqlite3_limit(id: c_int, newVal: c_int ):c_int;
extern proc  sqlite3_prepare(db:c_ptr(sqlite3), zSql: c_string, nByte: c_int, ppStmt: c_ptr(sqlite3_stmt ), pzTail: c_string ):c_int;
extern proc  sqlite3_prepare_v2(db:c_ptr(sqlite3),zSql: c_string, nByte: c_int, ref ppStmt: sqlite3_stmtptr, pzTail: c_stringptr ):c_int;
extern proc  sqlite3_prepare16(db:c_ptr(sqlite3), zSql: c_void_ptr, nByte: c_int, ppStmt: c_ptr(sqlite3_stmt ), pzTail: c_void_ptr ):c_int;
extern proc  sqlite3_prepare16_v2(db:c_ptr(sqlite3),zSql: c_void_ptr, nByte: c_int, ppStmt: c_ptr(sqlite3_stmt ), pzTail: c_void_ptr ):c_int;
extern proc  sqlite3_sql(db:c_ptr(sqlite3),pStmt: c_ptr(sqlite3_stmt ) ):c_string;
extern proc  sqlite3_expanded_sql(db:c_ptr(sqlite3),pStmt: c_ptr(sqlite3_stmt ) ):c_ptr(c_char);
extern proc  sqlite3_stmt_readonly(db:c_ptr(sqlite3),pStmt: c_ptr(sqlite3_stmt ) ):c_int;
extern proc  sqlite3_stmt_busy(db:c_ptr(sqlite3),args1: c_ptr(sqlite3_stmt ) ):c_int;

extern record sqlite3_value{
}


extern record sqlite3_context{
}

//extern proc  sqlite3_bind_blob(args2: c_int, args3: c_void_ptr, n: c_int, args5: c_ptr(void ()(void )) ):c_int;
//extern proc  sqlite3_bind_blob64(args2: c_int, args3: c_void_ptr, args4: sqlite3_uint64, args5: c_ptr(void ()(void )) ):c_int;
extern proc  sqlite3_bind_double(args2: c_int, args3: double ):c_int;
extern proc  sqlite3_bind_int(args2: c_int, args3: c_int ):c_int;
extern proc  sqlite3_bind_int64(args2: c_int, args3: sqlite3_int64 ):c_int;
extern proc  sqlite3_bind_null(args2: c_int ):c_int;
//extern proc  sqlite3_bind_text(args2: c_int, args3: c_string, args4: c_int, args5: c_ptr(void ()(void )) ):c_int;
//extern proc  sqlite3_bind_text16(args2: c_int, args3: c_void_ptr, args4: c_int, args5: c_ptr(void ()(void )) ):c_int;
//extern proc  sqlite3_bind_text64(args2: c_int, args3: c_string, args4: sqlite3_uint64, args5: c_ptr(void ()(void )), encoding: c_uchar ):c_int;
extern proc  sqlite3_bind_value(args2: c_int, args3: c_ptr(sqlite3_value ) ):c_int;
extern proc  sqlite3_bind_zeroblob(args2: c_int, n: c_int ):c_int;
extern proc  sqlite3_bind_zeroblob64(args2: c_int, args3: sqlite3_uint64 ):c_int;
extern proc  sqlite3_bind_parameter_count(args1: c_ptr(sqlite3_stmt ) ):c_int;
extern proc  sqlite3_bind_parameter_name(args2: c_int ):c_string;
extern proc  sqlite3_bind_parameter_index(zName: c_string ):c_int;
extern proc  sqlite3_clear_bindings(args1: c_ptr(sqlite3_stmt ) ):c_int;
extern proc  sqlite3_column_count(pStmt: c_ptr(sqlite3_stmt ) ):c_int;
extern proc  sqlite3_column_name(pStmt: c_ptr(sqlite3_stmt ),N: c_int ):c_string;
extern proc  sqlite3_column_name16(pStmt: c_ptr(sqlite3_stmt ), N: c_int ):c_void_ptr;
extern proc  sqlite3_column_database_name(pStmt: c_ptr(sqlite3_stmt ),args2: c_int ):c_string;
extern proc  sqlite3_column_database_name16(pStmt: c_ptr(sqlite3_stmt ), args2: c_int ):c_void_ptr;
extern proc  sqlite3_column_table_name(pStmt: c_ptr(sqlite3_stmt ),args2: c_int ):c_string;
extern proc  sqlite3_column_table_name16(pStmt: c_ptr(sqlite3_stmt ), args2: c_int ):c_void_ptr;
extern proc  sqlite3_column_origin_name(pStmt: c_ptr(sqlite3_stmt ), args2: c_int ):c_string;
extern proc  sqlite3_column_origin_name16(pStmt: c_ptr(sqlite3_stmt ), args2: c_int ):c_void_ptr;
extern proc  sqlite3_column_decltype(pStmt: c_ptr(sqlite3_stmt ), args2: c_int ):c_string;
extern proc  sqlite3_column_decltype16(pStmt: c_ptr(sqlite3_stmt ), args2: c_int ):c_void_ptr;
extern proc  sqlite3_step(args1: c_ptr(sqlite3_stmt ) ):c_int;
extern proc  sqlite3_data_count(pStmt: c_ptr(sqlite3_stmt ) ):c_int;
extern proc  sqlite3_column_blob(pStmt: c_ptr(sqlite3_stmt ),iCol: c_int ):c_string;
extern proc  sqlite3_column_bytes(pStmt: c_ptr(sqlite3_stmt ),iCol: c_int ):c_int;
extern proc  sqlite3_column_bytes16(pStmt: c_ptr(sqlite3_stmt ),iCol: c_int ):c_int;
extern proc  sqlite3_column_double(pStmt: c_ptr(sqlite3_stmt ),iCol: c_int ):double;
extern proc  sqlite3_column_int(pStmt: c_ptr(sqlite3_stmt ),iCol: c_int ):c_int;
extern proc  sqlite3_column_int64(pStmt: c_ptr(sqlite3_stmt ),_sqlite3_int64: sqlite3_int64, args2: c_ptr(sqlite3_stmt ), iCol: c_int ):sqlite3_int64;
//extern proc  sqlite3_column_text(pStmt: c_ptr(sqlite3_stmt ),iCol: c_int ):c_ptr(c_uint);
extern proc  sqlite3_column_text(pStmt: c_ptr(sqlite3_stmt ),iCol: c_int ):c_string;

extern proc  sqlite3_column_text16(pStmt: c_ptr(sqlite3_stmt ),iCol: c_int ):c_void_ptr;
extern proc  sqlite3_column_type(pStmt: c_ptr(sqlite3_stmt ),iCol: c_int ):c_int;
extern proc  sqlite3_column_value(_sqlite3_value: sqlite3_value, args2: c_ptr(sqlite3_stmt ), iCol: c_int ):c_ptr(sqlite3_value );
extern proc  sqlite3_finalize(pStmt: c_ptr(sqlite3_stmt ) ):c_int;
extern proc  sqlite3_reset(pStmt: c_ptr(sqlite3_stmt ) ):c_int;
//extern proc  sqlite3_create_function(zFunctionName: c_string, nArg: c_int, eTextRep: c_int, pApp: c_void_ptr, xFunc: c_ptr(void ()(sqlite3_context , int, sqlite3_value )), xStep: c_ptr(void ()(sqlite3_context , int, sqlite3_value )), xFinal: c_ptr(void ()(sqlite3_context )) ):c_int;
//extern proc  sqlite3_create_function16(zFunctionName: c_void_ptr, nArg: c_int, eTextRep: c_int, pApp: c_void_ptr, xFunc: c_ptr(void ()(sqlite3_context , int, sqlite3_value )), xStep: c_ptr(void ()(sqlite3_context , int, sqlite3_value )), xFinal: c_ptr(void ()(sqlite3_context )) ):c_int;
//extern proc  sqlite3_create_function_v2(zFunctionName: c_string, nArg: c_int, eTextRep: c_int, pApp: c_void_ptr, xFunc: c_ptr(void ()(sqlite3_context , int, sqlite3_value )), xStep: c_ptr(void ()(sqlite3_context , int, sqlite3_value )), xFinal: c_ptr(void ()(sqlite3_context )), xDestroy: c_ptr(void ()(void )) ):c_int;
extern proc  sqlite3_aggregate_count(args1: c_ptr(sqlite3_context ) ):c_int;
extern proc  sqlite3_expired(args1: c_ptr(sqlite3_stmt ) ):c_int;
extern proc  sqlite3_transfer_bindings(args2: c_ptr(sqlite3_stmt ) ):c_int;
extern proc  sqlite3_global_recover():c_int;
extern proc  sqlite3_thread_cleanup():c_void_ptr;
extern proc  sqlite3_memory_alarm(args2: c_void_ptr, args3: sqlite3_int64 ):c_int;
extern proc  sqlite3_value_blob(args1: c_ptr(sqlite3_value ) ):c_void_ptr;
extern proc  sqlite3_value_bytes(args1: c_ptr(sqlite3_value ) ):c_int;
extern proc  sqlite3_value_bytes16(args1: c_ptr(sqlite3_value ) ):c_int;
extern proc  sqlite3_value_double(args1: c_ptr(sqlite3_value ) ):double;
extern proc  sqlite3_value_int(args1: c_ptr(sqlite3_value ) ):c_int;
extern proc  sqlite3_value_int64(_sqlite3_int64: sqlite3_int64, args2: c_ptr(sqlite3_value ) ):sqlite3_int64;
extern proc  sqlite3_value_text(args1: c_ptr(sqlite3_value ) ):c_ptr(c_uchar );
extern proc  sqlite3_value_text16(args1: c_ptr(sqlite3_value ) ):c_void_ptr;
extern proc  sqlite3_value_text16le(args1: c_ptr(sqlite3_value ) ):c_void_ptr;
extern proc  sqlite3_value_text16be(args1: c_ptr(sqlite3_value ) ):c_void_ptr;
extern proc  sqlite3_value_type(args1: c_ptr(sqlite3_value ) ):c_int;
extern proc  sqlite3_value_numeric_type(args1: c_ptr(sqlite3_value ) ):c_int;
extern proc  sqlite3_value_subtype(args1: c_ptr(sqlite3_value ) ):c_uint;
extern proc  sqlite3_value_dup(_sqlite3_value: sqlite3_value, args2: c_ptr(sqlite3_value ) ):c_ptr(sqlite3_value );
extern proc  sqlite3_value_free(args1: c_ptr(sqlite3_value ) ):c_void_ptr;
extern proc  sqlite3_aggregate_context(nBytes: c_int ):c_void_ptr;
extern proc  sqlite3_user_data(args1: c_ptr(sqlite3_context ) ):c_void_ptr;
extern proc  sqlite3_context_db_handle(_sqlite3: sqlite3, args2: c_ptr(sqlite3_context ) ):c_ptr(sqlite3 );
extern proc  sqlite3_get_auxdata(N: c_int ):c_void_ptr;
//extern proc  sqlite3_set_auxdata(N: c_int, args3: c_void_ptr, args4: c_ptr(void ()(void )) ):c_void_ptr;
extern record sqlite3_destructor_type{
}

//extern proc  sqlite3_result_blob(args2: c_void_ptr, args3: c_int, args4: c_ptr(void ()(void )) ):c_void_ptr;
//extern proc  sqlite3_result_blob64(args2: c_void_ptr, args3: sqlite3_uint64, args4: c_ptr(void ()(void )) ):c_void_ptr;
extern proc  sqlite3_result_double(args2: double ):c_void_ptr;
extern proc  sqlite3_result_error(args2: c_string, args3: c_int ):c_void_ptr;
extern proc  sqlite3_result_error16(args2: c_void_ptr, args3: c_int ):c_void_ptr;
extern proc  sqlite3_result_error_toobig(args1: c_ptr(sqlite3_context ) ):c_void_ptr;
extern proc  sqlite3_result_error_nomem(args1: c_ptr(sqlite3_context ) ):c_void_ptr;
extern proc  sqlite3_result_error_code(args2: c_int ):c_void_ptr;
extern proc  sqlite3_result_int(args2: c_int ):c_void_ptr;
extern proc  sqlite3_result_int64(args2: sqlite3_int64 ):c_void_ptr;
extern proc  sqlite3_result_null(args1: c_ptr(sqlite3_context ) ):c_void_ptr;
//extern proc  sqlite3_result_text(args2: c_string, args3: c_int, args4: c_ptr(void ()(void )) ):c_void_ptr;
//extern proc  sqlite3_result_text64(args2: c_string, args3: sqlite3_uint64, args4: c_ptr(void ()(void )), encoding: c_uchar ):c_void_ptr;
//extern proc  sqlite3_result_text16(args2: c_void_ptr, args3: c_int, args4: c_ptr(void ()(void )) ):c_void_ptr;
//extern proc  sqlite3_result_text16le(args2: c_void_ptr, args3: c_int, args4: c_ptr(void ()(void )) ):c_void_ptr;
//extern proc  sqlite3_result_text16be(args2: c_void_ptr, args3: c_int, args4: c_ptr(void ()(void )) ):c_void_ptr;
extern proc  sqlite3_result_value(args2: c_ptr(sqlite3_value ) ):c_void_ptr;
extern proc  sqlite3_result_zeroblob(n: c_int ):c_void_ptr;
extern proc  sqlite3_result_zeroblob64(n: sqlite3_uint64 ):c_int;
extern proc  sqlite3_result_subtype(args2: c_uint ):c_void_ptr;
//extern proc  sqlite3_create_collation(zName: c_string, eTextRep: c_int, pArg: c_void_ptr, xCompare: c_ptr(int ()(void , int, const void , int, const void )) ):c_int;
//extern proc  sqlite3_create_collation_v2(zName: c_string, eTextRep: c_int, pArg: c_void_ptr, xCompare: c_ptr(int ()(void , int, const void , int, const void )), xDestroy: c_ptr(void ()(void )) ):c_int;
//extern proc  sqlite3_create_collation16(zName: c_void_ptr, eTextRep: c_int, pArg: c_void_ptr, xCompare: c_ptr(int ()(void , int, const void , int, const void )) ):c_int;
//extern proc  sqlite3_collation_needed(args2: c_void_ptr, args3: c_ptr(void ()(void , sqlite3 , int, const char )) ):c_int;
//extern proc  sqlite3_collation_needed16(args2: c_void_ptr, args3: c_ptr(void ()(void , sqlite3 , int, const void )) ):c_int;
extern proc  sqlite3_sleep(args1: c_int ):c_int;
extern proc  sqlite3_get_autocommit(args1: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_db_handle(_sqlite3: sqlite3, args2: c_ptr(sqlite3_stmt ) ):c_ptr(sqlite3 );
extern proc  sqlite3_db_filename(zDbName: c_string ):c_string;
extern proc  sqlite3_db_readonly(zDbName: c_string ):c_int;
extern proc  sqlite3_next_stmt(_sqlite3_stmt: sqlite3_stmt, pDb: c_ptr(sqlite3 ), pStmt: c_ptr(sqlite3_stmt ) ):c_ptr(sqlite3_stmt );
//extern proc  sqlite3_commit_hook(args2: c_ptr(int ()(void )), args3: c_void_ptr ):c_void_ptr;
//extern proc  sqlite3_rollback_hook(args2: c_ptr(void ()(void )), args3: c_void_ptr ):c_void_ptr;
//extern proc  sqlite3_update_hook(args2: c_ptr(void ()(void , int, const char , const char , sqlite3_int64)), args3: c_void_ptr ):c_void_ptr;
extern proc  sqlite3_enable_shared_cache(args1: c_int ):c_int;
extern proc  sqlite3_release_memory(args1: c_int ):c_int;
extern proc  sqlite3_db_release_memory(args1: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_soft_heap_limit64(_sqlite3_int64: sqlite3_int64, N: sqlite3_int64 ):sqlite3_int64;
extern proc  sqlite3_soft_heap_limit(N: c_int ):c_void_ptr;
extern proc  sqlite3_table_column_metadata(zDbName: c_string, zTableName: c_string, zColumnName: c_string, pzDataType: c_string, pzCollSeq: c_string, pNotNull: c_ptr(c_int), pPrimaryKey: c_ptr(c_int), pAutoinc: c_ptr(c_int) ):c_int;
extern proc  sqlite3_load_extension(zFile: c_string, zProc: c_string, pzErrMsg: c_ptr(char ) ):c_int;
extern proc  sqlite3_enable_load_extension(onoff: c_int ):c_int;
//extern proc  sqlite3_auto_extension(xEntryPoint: c_ptr(void ()(void)) ):c_int;
//extern proc  sqlite3_cancel_auto_extension(xEntryPoint: c_ptr(void ()(void)) ):c_int;
extern proc  sqlite3_reset_auto_extension():c_void_ptr;


extern record sqlite3_vtab{
}


extern record sqlite3_index_info{
}


extern record sqlite3_vtab_cursor{
}


extern record sqlite3_module{
}


extern proc  sqlite3_create_module(zName: c_string, p: c_ptr(sqlite3_module ), pClientData: c_void_ptr ):c_int;
extern proc  sqlite3_create_module_v2(zName: c_string, p: c_ptr(sqlite3_module ), pClientData: c_void_ptr, xDestroy: c_ptr(void ()(void )) ):c_int;


extern proc  sqlite3_declare_vtab(zSQL: c_string ):c_int;
extern proc  sqlite3_overload_function(zFuncName: c_string, nArg: c_int ):c_int;

extern record sqlite3_blob{
}

extern proc  sqlite3_blob_open(zDb: c_string, zTable: c_string, zColumn: c_string, iRow: sqlite3_int64, flags: c_int, ppBlob: c_ptr(sqlite3_blob ) ):c_int;
extern proc  sqlite3_blob_reopen(args2: sqlite3_int64 ):c_int;
extern proc  sqlite3_blob_close(args1: c_ptr(sqlite3_blob ) ):c_int;
extern proc  sqlite3_blob_bytes(args1: c_ptr(sqlite3_blob ) ):c_int;
extern proc  sqlite3_blob_read(Z: c_void_ptr, N: c_int, iOffset: c_int ):c_int;
extern proc  sqlite3_blob_write(z: c_void_ptr, n: c_int, iOffset: c_int ):c_int;
extern proc  sqlite3_vfs_find(_sqlite3_vfs: sqlite3_vfs, zVfsName: c_string ):c_ptr(sqlite3_vfs );
extern proc  sqlite3_vfs_register(makeDflt: c_int ):c_int;
extern proc  sqlite3_vfs_unregister(args1: c_ptr(sqlite3_vfs ) ):c_int;
extern proc  sqlite3_mutex_alloc(_sqlite3_mutex: sqlite3_mutex, args2: c_int ):c_ptr(sqlite3_mutex );
extern proc  sqlite3_mutex_free(args1: c_ptr(sqlite3_mutex ) ):c_void_ptr;
extern proc  sqlite3_mutex_enter(args1: c_ptr(sqlite3_mutex ) ):c_void_ptr;
extern proc  sqlite3_mutex_try(args1: c_ptr(sqlite3_mutex ) ):c_int;
extern proc  sqlite3_mutex_leave(args1: c_ptr(sqlite3_mutex ) ):c_void_ptr;

extern record sqlite3_mutex_methods{
}


extern proc  sqlite3_mutex_held(args1: c_ptr(sqlite3_mutex ) ):c_int;
extern proc  sqlite3_mutex_notheld(args1: c_ptr(sqlite3_mutex ) ):c_int;
extern proc  sqlite3_db_mutex(_sqlite3_mutex: sqlite3_mutex, args2: c_ptr(sqlite3 ) ):c_ptr(sqlite3_mutex );
extern proc  sqlite3_file_control(zDbName: c_string, op: c_int, args4: c_void_ptr ):c_int;
extern proc  sqlite3_test_control(op: c_int ):c_int;
extern proc  sqlite3_status(pCurrent: c_ptr(c_int), pHighwater: c_ptr(c_int), resetFlag: c_int ):c_int;
extern proc  sqlite3_status64(pCurrent: c_ptr(sqlite3_int64 ), pHighwater: c_ptr(sqlite3_int64 ), resetFlag: c_int ):c_int;
extern proc  sqlite3_db_status(op: c_int, pCur: c_ptr(c_int), pHiwtr: c_ptr(c_int), resetFlg: c_int ):c_int;
extern proc  sqlite3_stmt_status(op: c_int, resetFlg: c_int ):c_int;

extern record sqlite3_pcache{
}


extern record sqlite3_pcache_page{
}


extern record sqlite3_pcache_methods2{
}


extern record sqlite3_pcache_methods{
}



extern record sqlite3_backup{
}

extern proc  sqlite3_backup_init(_sqlite3_backup: sqlite3_backup, pDest: c_ptr(sqlite3 ), zDestName: c_string, pSource: c_ptr(sqlite3 ), zSourceName: c_string ):c_ptr(sqlite3_backup );
extern proc  sqlite3_backup_step(nPage: c_int ):c_int;
extern proc  sqlite3_backup_finish(p: c_ptr(sqlite3_backup ) ):c_int;
extern proc  sqlite3_backup_remaining(p: c_ptr(sqlite3_backup ) ):c_int;
extern proc  sqlite3_backup_pagecount(p: c_ptr(sqlite3_backup ) ):c_int;
//extern proc  sqlite3_unlock_notify(xNotify: c_ptr(void ()(void , int)), pNotifyArg: c_void_ptr ):c_int;
extern proc  sqlite3_stricmp(args2: c_string ):c_int;
extern proc  sqlite3_strnicmp(args2: c_string, args3: c_int ):c_int;
extern proc  sqlite3_strglob(zStr: c_string ):c_int;
extern proc  sqlite3_strlike(zStr: c_string, cEsc: c_uint ):c_int;
extern proc  sqlite3_log(zFormat: c_string ):c_void_ptr;
//extern proc  sqlite3_wal_hook(args2: c_ptr(int ()(void , sqlite3 , const char , int)), args3: c_void_ptr ):c_void_ptr;
extern proc  sqlite3_wal_autocheckpoint(N: c_int ):c_int;
extern proc  sqlite3_wal_checkpoint(zDb: c_string ):c_int;
extern proc  sqlite3_wal_checkpoint_v2(zDb: c_string, eMode: c_int, pnLog: c_ptr(c_int), pnCkpt: c_ptr(c_int) ):c_int;
extern proc  sqlite3_vtab_config(op: c_int ):c_int;
extern proc  sqlite3_vtab_on_conflict(args1: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_stmt_scanstatus(idx: c_int, iScanStatusOp: c_int, pOut: c_void_ptr ):c_int;
extern proc  sqlite3_stmt_scanstatus_reset(args1: c_ptr(sqlite3_stmt ) ):c_void_ptr;
extern proc  sqlite3_db_cacheflush(args1: c_ptr(sqlite3 ) ):c_int;
extern proc  sqlite3_system_errno(args1: c_ptr(sqlite3 ) ):c_int;

extern record sqlite3_snapshot{
}

extern proc  sqlite3_snapshot_get(zSchema: c_string, ppSnapshot: c_ptr(sqlite3_snapshot ) ):c_int;
extern proc  sqlite3_snapshot_open(zSchema: c_string, pSnapshot: c_ptr(sqlite3_snapshot ) ):c_int;
extern proc  sqlite3_snapshot_free(args1: c_ptr(sqlite3_snapshot ) ):c_void_ptr;
extern proc  sqlite3_snapshot_cmp(p2: c_ptr(sqlite3_snapshot ) ):c_int;
extern proc  sqlite3_snapshot_recover(zDb: c_string ):c_int;

extern record sqlite3_rtree_geometry{
}


extern record sqlite3_rtree_query_info{
}

extern record sqlite3_rtree_dbl{
}

//extern proc  sqlite3_rtree_geometry_callback(zGeom: c_string, xGeom: c_ptr(int ()(sqlite3_rtree_geometry , int, sqlite3_rtree_dbl , int )), pContext: c_void_ptr ):c_int;

//extern proc  sqlite3_rtree_query_callback(zQueryFunc: c_string, xQueryFunc: c_ptr(int ()(sqlite3_rtree_query_info )), pContext: c_void_ptr, xDestructor: c_ptr(void ()(void )) ):c_int;

extern record Fts5ExtensionApi{
}


extern record Fts5Context{
}


extern record Fts5PhraseIter{
}

extern record fts5_extension_function{
}


extern record Fts5Tokenizer{
}


extern record fts5_tokenizer{
}


extern record fts5_api{
}


}//SqliteNative
}//Sqlite Module