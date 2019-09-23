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
module Mysql{
    use Cdo;
    use SysBasic;
	use MysqlNative;
    use List;
    use Map;
    

    require "my_global.h";
    require "mysql.h" ;
    require "stdio.h";
	require "mysql_helper.h";



proc MysqlConnectionFactory(host: string, user: string = "", database: string = "", 
                            passwd: string = ""): MysqlConnection {
    return new MysqlConnection(host, user, database, passwd);
} 


class MysqlConnection: ConnectionBase{

     var dsn: string;
     var conn: c_ptr(MYSQL);
     var _autocommit: bool;
     var _tmp_autocommit: bool;

     proc init(host:string, user:string = "", database: string = "", passwd: string = "") {
        this.conn = nil;
        this._autocommit=true;
        this._tmp_autocommit=true;
            
		this.conn = mysql_init(this.conn);

  		if (mysql_real_connect(this.conn, host.localize().c_str(), user.localize().c_str(), 
            passwd.localize().c_str(),database.localize().c_str(), 0, 
            c_nil:c_string, 0) == c_nil) 
        {
      		writeln("Error connect");
      		mysql_close(this.conn);
      		exit(1);
  		}  

		this.setAutocommit(true);
    }

    proc getNativeConection(): c_ptr(MYSQL) {
        return this.conn;    
    }

    proc helloWorld() {
        writeln("Hello from MysqlConnection");
    }

    override proc cursor() {
        return new MysqlCursor(this,this.conn);
    }

    override proc Begin() {
        this.setAutocommit(false);
        mysql_query(this.conn,"START TRANSACTION;"); 
    }

    override proc commit() {

        mysql_commit(this.conn);
    
        if(!this.isAutoCommit() && (this._tmp_autocommit==true)) {
            this.setAutocommit(true);
        }
    }

    override proc rollback() {
        mysql_rollback(this.conn);
        if(!this.isAutoCommit() && (this._tmp_autocommit==true)) {
            this.setAutocommit(true);
        }
    }

    override proc setAutocommit(commit: bool) {
        this._tmp_autocommit = this._autocommit;
        this._autocommit = commit;

        if(commit==true) {
            mysql_autocommit(this.conn, 1);
            mysql_query(this.conn,"SET autocommit = 1;");
        }
        else {
            mysql_autocommit(this.conn, 0);
            mysql_query(this.conn,"SET autocommit = 0;");
        }
    }

    proc isAutoCommit(): bool {
        return this._autocommit;
    }


    override proc close() {
		mysql_close(this.conn);
    }

    override proc Table(table: string): QueryBuilder {
        return new QueryBuilder(new MySqlQueryBuilder(this,table));
    }

    override proc table(table: string): QueryBuilder {
       return new QueryBuilder(new MySqlQueryBuilder());
    }

}

class MysqlCursor:CursorBase{
    
    var con: MysqlConnection;
    var mycon: c_ptr(MYSQL);
    var res: c_ptr(MYSQL_RES);
    var fields: c_ptr(MYSQL_FIELD);
    var nFields: int(32);
    var numRows: int(32);
    var curRow: int(32)=0;

    proc init(con: MysqlConnection, pgcon: c_ptr(MYSQL)) {
        this.con = con;
        this.mycon = pgcon;
        this.complete();
        this.__registerTypes();

    }

    proc __registerTypes() {
        this.__registerTypeName(20, "int"); // int8
    }

    proc __registerTypeName(oid: int, cdo_type: string) {
        //this.type_mapper[oid:string]= cdo_type;
    }

    proc __typeToString(oid: c_int): string {
        /*if(this.mapperDom.member(oid:string)){
            return this.type_mapper[oid:string];
        }*/
        return oid: string;        
    }

    proc rowcount(): int(32) {
        return this.numRows;
    }


    proc callproc() {

    }

    override proc close() {
        mysql_free_result(this.res);    
    }

    override proc execute(query: string, params) {
        try {
            this.execute(query.format((...params)));
        }
        catch {
            writeln("Error");
        }
    }

    override proc execute(query: string) {
		if (mysql_query(this.mycon,  query.localize().c_str())) {
      		writeln("Error query"); 
      		// mysql_close(this.mycon);
  		}

        this.__removeColumns();

		this.res = mysql_store_result(this.mycon);
		if ((this.res == c_nil) && (mysql_errno(this.mycon) != 0)) {
      		writeln("Error Result");
      		// mysql_close(this.mycon);
  		}
        else if((this.res == c_nil) && (mysql_errno(this.mycon) == 0)) {
			this.nFields =0;
		}
        else if((this.res != c_nil) && (mysql_errno(this.mycon)==0)) {
			this.nFields = mysql_num_fields(this.res):int(32);
			this.fields = mysql_fetch_fields(this.res);
        	var ii: int(32) = 0;
        	while (ii < this.nFields) {    
				var colname = createStringWithNewBuffer(
                    __get_mysql_field_name_by_number(this.fields,ii:c_int));
                //I need to get mysql type
            	//var coltype = this.__typeToString(PQftype(this.res,ii:c_int));
                
                this.__addColumn(ii,colname);
            	ii += 1;
        	}
        	this.numRows = mysql_num_rows(this.res): int(32);
        	this.curRow = 0;
		}
    }

    override proc query(query: string) {
       this.execute(query);
    }

    override proc query(query: string, params) {
        try {
            this.query(query.format((...params)));
        }
        catch {
            writeln("Error");
        }
    }

    override proc dump() {
        var res = this.res;
        var i = 0;
        var j = 0;
        var row = "";
        var rows = this.numRows: int;
        while (i < rows) {       
            j = 0;
            while(j < this.nFields) {
                //row = new string(PQgetvalue(res, i:c_int, j:c_int):c_string);

                // printf("\t%s".localize().c_str(),PQgetvalue(res,  i:c_int, j:c_int));
                //write("\t",row);
                //write("\t",PQgetvalue(res,  i:c_int, j:c_int):string);
           
                j += 1;
            }       
            writeln("\n");
            i += 1;
        }
    }

    override proc executemany(str: string, pr){
        try {
            writeln(str.format((...pr)));
        }
        catch {
            writeln("Error");
        }
        //for p in pr{
            //writeln(p);
        //}
    }

    proc fetchrow(idx: int): owned Row {
        if(idx > this.rowcount()){
            return new Row(valid = false);
        }

        var row = new Row(valid = true);
        this.curRow = idx: int(32);

		mysql_data_seek(this.res, this.curRow: c_int);
		
		var _row = mysql_fetch_row(this.res);
       	var j: int(32) = 0;
		while(j < this.nFields) {
            var datum = new string(__get_mysql_row_by_number(_row, j: c_int));
            var colinfo = this.getColumnInfo(j);
            row.addData(colinfo.name,datum);
            j += 1;
        }
        this.curRow += 1;
        return row;
    }

    override proc this(idx: int): owned Row {
        return this.fetchrow(idx);
    }

    override iter these()ref{
        for row in this.fetchall(){
            yield row;
        }
    }

    override proc fetchone(): owned Row {
        if this.curRow == this.numRows {
            return new Row(valid = false);
        }
       	var row = new Row(valid = true);

       	var j: int(32) = 0;
		mysql_data_seek(this.res, this.curRow: c_int);
		var _row = mysql_fetch_row(this.res);
       	
		while(j < this.nFields) {
            var datum = createStringWithNewBuffer(
                        __get_mysql_row_by_number(_row, j: c_int));
            var colinfo = this.getColumnInfo(j);
            row.addData(colinfo.name,datum);
            j += 1;
        }
        this.curRow += 1;
        return row;
    }

    override iter fetchmany(count: int=0): owned Row {
        if(count <= 0) {
            for row in this.fetchall() {
                yield row;
            }
        }
        else {
            var idx = 0;
            var res:Row = this.fetchone();    
            while((res.isValid()) && (idx<this.rowcount()) && (idx<count)) {
                yield res;
                res = this.fetchone();
                idx += 1;
            }
        }
    }

    override iter fetchall(): owned Row {

        var res: Row = this.fetchone();
        while(res.isValid()) {
            yield res;
            res = this.fetchone();
        }
    }

    override proc next(): owned Row{
        return this.fetchone();
    }

    override proc messages() {}

    proc __quote_columns(colname: string): string {
        if(colname == "*") {
            return "*";
        }
        return "`" + colname + "`";
    }

    proc __quote_values(value: string): string{
        return "'" + value + "'";
    }

    override proc insertRecord(table: string, ref el: ?eltType): string {
        var cols = this.__objToArray(el);
        return this.insert(table, cols);       
    }

    override proc insert(table: string, data:map(string, string, parSafe = true)): string{
        var colset: list(string);
        var valset: list(string);

        for idx in data{
            colset.append(this.__quote_columns(idx));
            valset.append(this.__quote_values(data[idx]));
        }
        var cols_part = ", ".join(colset.toArray());
        var vals_part = ", ".join(valset.toArray());
        var sql = "";
        try {
            sql = "INSERT INTO %s(%s) VALUES(%s) ".format(table, cols_part, vals_part);
        }
        catch {
            writeln("Error on building insert query");
        }
        this.execute(sql);
        return sql;
    }


    override proc update(table: string, whereCond: string, 
                        data: map(string, string, parSafe = true)): string {
        var colvalset: list(string); 
        for idx in data {
            colvalset.append(this.__quote_columns(idx) + " = " + 
                            this.__quote_values(data[idx]));
        }
        var colsvals_part = ", ".join(colvalset.toArray());
        var sql = "";
        try {
            sql = "UPDATE %s SET %s WHERE (%s)".format(table, colsvals_part, whereCond);
        }
        catch {
            writeln("Error on building update query");
        }
        this.execute(sql);
        return sql;
    }

    proc update(table: string, whereCond: string, ref el: ?eltType): string {
        var cols = this.__objToArray(el);
        return this.update(table, whereCond, cols);
    }

    override proc updateRecord(table: string, whereCond: string, ref el: ?eltType): string {
        return this.update(table,whereCond,el);
    }

    override proc Delete(table: string, whereCond: string): string {
        var sql = "";
        try{
            sql = "DELETE FROM %s WHERE (%s)".format(table,whereCond);
        }catch{
            writeln("Error on formating delete statement");
        }
        this.execute(sql);
        return sql;
    }

}

class MySqlQueryBuilder:QueryBuilderBase {
    proc init() {}
}


module MysqlNative {

extern type char = int(8);

extern type my_bool = int(8);

extern type enum_session_state_type = int(32);
extern type mysql_enum_shutdown_level = int(32);
extern type enum_mysql_set_option = int(32);
extern type enum_stmt_attr_type = int(32);
extern type mysql_option;

extern record __u_char {
}

extern record __u_short{
}

extern record __u_int {
}

extern record __u_long {
}

extern record __int8_t {
}

extern record __uint8_t {
}

extern record __int16_t {
}

extern record __uint16_t {
}

extern record __int32_t {
}

extern record __uint32_t {
}

extern record __int64_t {
}

extern record __uint64_t {
}

extern record __quad_t {
}

extern record __u_quad_t {
}

extern record __intmax_t {
}

extern record __uintmax_t {
}

extern record __dev_t {
}

extern record __uid_t {
}

extern record __gid_t {
}

extern record __ino_t {
}

extern record __ino64_t {
}

extern record __mode_t {
}

extern record __nlink_t {
}

extern record __off_t {
}

extern record __off64_t {
}

extern record __pid_t {
}

extern record __fsid_t {
}

extern record __clock_t {
}

extern record __rlim_t {
}

extern record __rlim64_t {
}

extern record __id_t {
}

extern record __time_t {
}

extern record __useconds_t {
}

extern record __suseconds_t {
}

extern record __daddr_t {
}

extern record __key_t {
}

extern record __clockid_t {
}

extern record __timer_t {
}

extern record __blksize_t {
}

extern record __blkcnt_t {
}

extern record __blkcnt64_t {
}

extern record __fsblkcnt_t {
}

extern record __fsblkcnt64_t {
}

extern record __fsfilcnt_t {
}

extern record __fsfilcnt64_t {
}

extern record __fsword_t {
}

extern record __ssize_t {
}

extern record __syscall_slong_t {
}

extern record __syscall_ulong_t {
}

extern record __loff_t {
}

extern record __qaddr_t {
}

extern record __caddr_t {
}

extern record __intptr_t {
}

extern record __socklen_t {
}

extern record __sig_atomic_t {
}

extern record u_char {
}

extern record u_short {
}

extern record u_int {
}

extern record u_long {
}

extern record quad_t {
}

extern record u_quad_t {
}

extern record fsid_t {
}

extern record loff_t {
}

extern record ino_t {
}

extern record dev_t {
}

extern record gid_t {
}

extern record mode_t {
}

extern record nlink_t {
}

extern record uid_t {
}

extern record off_t {
}

extern record pid_t {
}

extern record id_t {
}

extern record ssize_t {
}

extern record daddr_t {
}

extern record caddr_t {
}

extern record key_t {
}

extern record clock_t {
}

extern record clockid_t {
}

extern record time_t {
}

extern record timer_t {
}

extern record ulong {
}

extern record ushort {
}

extern record int8_t {
}

extern record int16_t {
}

extern record int32_t {
}

extern record int64_t {
}

extern record u_int8_t {
}

extern record u_int16_t {
}

extern record u_int32_t {
}

extern record u_int64_t {
}

extern record register_t {
}

extern record my_socket {
}


extern "struct st_mysql_client_plugin" record st_mysql_client_plugin {
	
	var interface_version: c_uint;
	var name: c_string;
	var author: c_string;
	var desc: c_string;
	//var version: unsigned int [3];
	var license: c_string;
	var mysql_api: c_void_ptr;
	//var init: c_ptr(int ()(char , int, int, int));
	//var deinit: c_ptr(int ()(void));
	//var options: c_ptr(int ()(const char , const void));
}

extern "struct st_mysql" record st_mysql {
}

extern "struct st_plugin_vio_info" record st_plugin_vio_info {
	var socket: c_int;
}

extern record MYSQL_PLUGIN_VIO_INFO {
}

extern "struct st_plugin_vio" record st_plugin_vio {
	//var read_packet: c_ptr(int ()(st_plugin_vio , unsigned char));
	//var write_packet: c_ptr(int ()(st_plugin_vio , const unsigned char , int));
	//var info: c_ptr(void ()(st_plugin_vio , st_plugin_vio_info));
}

extern record MYSQL_PLUGIN_VIO {
}

extern "struct st_mysql_client_plugin_AUTHENTICATION" record 
        st_mysql_client_plugin_AUTHENTICATION {
	
	var interface_version: c_uint;
	var name: c_string;
	var author: c_string;
	var desc: c_string;
	//var version: unsigned int [3];
	var license: c_string;
	var mysql_api: c_void_ptr;
	//var init: c_ptr(int ()(char , int, int, int));
	//var deinit: c_ptr(int ()(void));
	//var options: c_ptr(int ()(const char , const void));
	//var authenticate_user: c_ptr(int ()(MYSQL_PLUGIN_VIO , st_mysql));
}

extern proc  mysql_load_plugin(_struct_st_mysql_client_plugin: st_mysql_client_plugin,
                                mysql: c_ptr(st_mysql), name: c_string, _type: c_int,
                                argc: c_int):c_ptr(st_mysql_client_plugin);

extern proc  mysql_load_plugin_v(_struct_st_mysql_client_plugin: st_mysql_client_plugin,
                                mysql: c_ptr(st_mysql), name: c_string, _type: c_int, 
                                argc: c_int, args: c_int):c_ptr(st_mysql_client_plugin);

extern proc  mysql_client_find_plugin(_struct_st_mysql_client_plugin: 
                            st_mysql_client_plugin, mysql: c_ptr(st_mysql), 
                            name: c_string, _type: c_int): c_ptr(st_mysql_client_plugin);

extern proc  mysql_client_register_plugin(_struct_st_mysql_client_plugin: 
                    st_mysql_client_plugin, mysql: c_ptr(st_mysql), 
                    plugin: c_ptr(st_mysql_client_plugin)): c_ptr(st_mysql_client_plugin);

extern proc  mysql_plugin_options(option: c_string, value: c_void_ptr): c_int;
extern "struct st_mysql_field" record st_mysql_field {
}

extern record MYSQL_FIELD {
}

extern record MYSQL_ROW {
}

extern record MYSQL_FIELD_OFFSET {
}

extern type my_ulonglong = int;

extern "struct PSI_thread" record PSI_thread {
}

extern record PSI_memory_key {
}

extern "struct st_used_mem" record st_used_mem {
	var next: c_ptr(st_used_mem);
	var left: c_uint;
	var size: c_uint;
}

extern record USED_MEM {
}

extern "struct st_mem_root" record st_mem_root {
}

extern record MEM_ROOT {
}

extern "struct st_typelib" record st_typelib {
	var count: c_uint;
	var name: c_string;
	var type_names:  c_string;
	var type_lengths: c_ptr(c_uint);
}

extern record TYPELIB {
}

extern proc  find_typeset(x: c_ptr(c_char), typelib: c_ptr(TYPELIB), 
                            error_position: c_ptr(c_int)): my_ulonglong;

extern proc  find_type_or_exit(typelib: c_ptr(TYPELIB), option: c_string): c_int;
extern proc  find_type(typelib: c_ptr(TYPELIB), flags: c_uint): c_int;
extern proc  make_type(nr: c_uint, typelib: c_ptr(TYPELIB)): c_void_ptr;
extern proc  get_type(nr: c_uint):c_string;
extern proc  copy_typelib(_TYPELIB: TYPELIB, root: c_ptr(MEM_ROOT), 
                        from: c_ptr(TYPELIB)):c_ptr(TYPELIB);

extern proc  find_set_from_flags(lib: c_ptr(TYPELIB), default_name: c_uint, 
                            cur_set: my_ulonglong, default_set: my_ulonglong, 
                            str: c_string, length: c_uint, err_pos: c_ptr(int(8)), 
                            err_len: c_ptr(c_uint)): my_ulonglong;

extern "struct st_mysql_rows" record st_mysql_rows {
	var next: c_ptr(st_mysql_rows);
	var data: MYSQL_ROW;
	var length: c_ulong;
}

extern record MYSQL_ROWS {
}

extern record MYSQL_ROW_OFFSET {
}

extern "struct embedded_query_result" record embedded_query_result {
}

extern record EMBEDDED_QUERY_RESULT {
}

extern "struct st_mysql_data" record st_mysql_data {
	var data: c_ptr(MYSQL_ROWS);
	var embedded_info: c_ptr(embedded_query_result);
	var alloc: MEM_ROOT;
	var rows: my_ulonglong;
	var fields: c_uint;
	var extension: c_void_ptr;
}

extern record MYSQL_DATA {
}

extern "struct st_mysql_options_extention" record st_mysql_options_extention {
}

extern "struct st_mysql_options" record st_mysql_options {
}

extern "struct character_set" record character_set {
}

extern record MY_CHARSET_INFO {
}

extern "struct st_mysql_methods" record st_mysql_methods {
}

extern "struct st_mysql_stmt" record st_mysql_stmt {
}

extern record MYSQL {
}

extern "struct st_mysql_res" record st_mysql_res {	
}

extern record MYSQL_RES {
}

extern proc  mysql_server_init(argv: c_ptr(char), groups: c_ptr(char)): c_int;
extern proc  mysql_server_end(): c_void_ptr;
extern proc  mysql_thread_init(_my_bool: my_bool): my_bool;
extern proc  mysql_thread_end(): c_void_ptr;
extern proc  mysql_num_rows(res: c_ptr(MYSQL_RES)): my_ulonglong;
extern proc  mysql_num_fields(res: c_ptr(MYSQL_RES)): c_uint;
extern proc  mysql_eof(res: c_ptr(MYSQL_RES)): my_bool;
extern proc  mysql_fetch_field_direct(res: c_ptr(MYSQL_RES), fieldnr: c_uint): c_ptr(MYSQL_FIELD);
extern proc  mysql_fetch_fields(res: c_ptr(MYSQL_RES)): c_ptr(MYSQL_FIELD);
extern proc  mysql_row_tell(res: c_ptr(MYSQL_RES)): MYSQL_ROW_OFFSET;
extern proc  mysql_field_tell(_MYSQL_FIELD_OFFSET: MYSQL_FIELD_OFFSET, res: c_ptr(MYSQL_RES)): MYSQL_FIELD_OFFSET;
extern proc  mysql_field_count(mysql: c_ptr(MYSQL)): c_uint;
extern proc  mysql_affected_rows(mysql: c_ptr(MYSQL)): my_ulonglong;
extern proc  mysql_insert_id(mysql: c_ptr(MYSQL)): my_ulonglong;
extern proc  mysql_errno(mysql: c_ptr(MYSQL)): c_uint;
extern proc  mysql_error(mysql: c_ptr(MYSQL)): c_string;
extern proc  mysql_sqlstate(mysql: c_ptr(MYSQL)): c_string;
extern proc  mysql_warning_count(mysql: c_ptr(MYSQL)): c_uint;
extern proc  mysql_info(mysql: c_ptr(MYSQL)): c_string;
extern proc  mysql_thread_id(mysql: c_ptr(MYSQL)): c_ulong;
extern proc  mysql_character_set_name(mysql: c_ptr(MYSQL)): c_string;
extern proc  mysql_set_character_set(csname: c_string): c_int;
extern proc  mysql_init(mysql: c_ptr(MYSQL)): c_ptr(MYSQL);
extern proc  mysql_ssl_set(mysql: c_ptr(MYSQL), key: c_string, cert: c_string, ca: c_string, capath: c_string, cipher: c_string): my_bool;
extern proc  mysql_get_ssl_cipher(mysql: c_ptr(MYSQL)): c_string;
extern proc  mysql_change_user(mysql: c_ptr(MYSQL), user: c_string, passwd: c_string, db: c_string): my_bool;
extern proc  mysql_real_connect(mysql: c_ptr(MYSQL), host: c_string, user: c_string, passwd: c_string, db: c_string, port: c_uint, unix_socket: c_string, clientflag: c_ulong): c_ptr(MYSQL);
extern proc  mysql_select_db(db: c_string): c_int;
extern proc  mysql_query(mysql:c_ptr(MYSQL), q: c_string): c_int;
extern proc  mysql_send_query(mysql:c_ptr(MYSQL),q: c_string, length: c_ulong): c_int;
extern proc  mysql_real_query(mysql:c_ptr(MYSQL),q: c_string, length: c_ulong): c_int;
extern proc  mysql_store_result(mysql: c_ptr(MYSQL)): c_ptr(MYSQL_RES);
extern proc  mysql_use_result(mysql: c_ptr(MYSQL)): c_ptr(MYSQL_RES);
extern proc  mysql_get_character_set_info(charset: c_ptr(MY_CHARSET_INFO)): c_void_ptr;
extern proc  mysql_session_track_get_first(__type:  enum_session_state_type, data:  c_string, length: c_ptr(c_int)): c_int;
extern proc  mysql_session_track_get_next(__type:  enum_session_state_type, data:  c_string, length: c_ptr(c_int)): c_int;
//extern proc  mysql_set_local_infile_handler(local_infile_init: c_ptr(int ()(void , const char , void)), local_infile_read: c_ptr(int ()(void , char , unsigned int)), local_infile_end: c_ptr(void ()(void)), local_infile_error: c_ptr(int ()(void , char , unsigned int)), args6: c_void_ptr):c_void_ptr;
extern proc  mysql_set_local_infile_default(mysql: c_ptr(MYSQL)): c_void_ptr;
extern proc  mysql_shutdown(shutdown_level:   mysql_enum_shutdown_level): c_int;
extern proc  mysql_dump_debug_info(mysql: c_ptr(MYSQL)): c_int;
extern proc  mysql_refresh(refresh_options: c_uint): c_int;
extern proc  mysql_kill(pid: c_ulong): c_int;
extern proc  mysql_set_server_option(option:   enum_mysql_set_option): c_int;
extern proc  mysql_ping(mysql: c_ptr(MYSQL)): c_int;
extern proc  mysql_stat(mysql: c_ptr(MYSQL)): c_string;
extern proc  mysql_get_server_info(mysql: c_ptr(MYSQL)): c_string;
extern proc  mysql_get_client_info(): c_string;
extern proc  mysql_get_client_version(): c_ulong;
extern proc  mysql_get_host_info(mysql: c_ptr(MYSQL)): c_string;
extern proc  mysql_get_server_version(mysql: c_ptr(MYSQL)): c_ulong;
extern proc  mysql_get_proto_info(mysql: c_ptr(MYSQL)): c_uint;
extern proc  mysql_list_dbs(mysql: c_ptr(MYSQL), wild: c_string): c_ptr(MYSQL_RES);
extern proc  mysql_list_tables(mysql: c_ptr(MYSQL), wild: c_string): c_ptr(MYSQL_RES);
extern proc  mysql_list_processes(mysql: c_ptr(MYSQL)): c_ptr(MYSQL_RES);
extern proc  mysql_options(option:   mysql_option, arg: c_void_ptr): c_int;
extern proc  mysql_options4(option:   mysql_option, arg1: c_void_ptr, arg2: c_void_ptr): c_int;
extern proc  mysql_get_option(option:   mysql_option, arg: c_void_ptr): c_int;
extern proc  mysql_free_result(result: c_ptr(MYSQL_RES)): c_void_ptr;
extern proc  mysql_data_seek(result: c_ptr(MYSQL_RES), offset: my_ulonglong): c_void_ptr;
extern proc  mysql_row_seek(result: c_ptr(MYSQL_RES), offset: MYSQL_ROW_OFFSET): MYSQL_ROW_OFFSET;
extern proc  mysql_field_seek(result: c_ptr(MYSQL_RES), offset: MYSQL_FIELD_OFFSET): MYSQL_FIELD_OFFSET;
extern proc  mysql_fetch_row(result: c_ptr(MYSQL_RES)): MYSQL_ROW;
extern proc  mysql_fetch_lengths(result: c_ptr(MYSQL_RES)): c_ptr(c_ulong);
extern proc  mysql_fetch_field(result: c_ptr(MYSQL_RES)): c_ptr(MYSQL_FIELD);
extern proc  mysql_list_fields(mysql: c_ptr(MYSQL), table: c_string, wild: c_string): c_ptr(MYSQL_RES);
extern proc  mysql_escape_string(from: c_string, from_length: c_ulong): c_ulong;
extern proc  mysql_hex_string(from: c_string, from_length: c_ulong): c_ulong;
extern proc  mysql_real_escape_string(to: c_ptr(c_char), from: c_string, length: c_ulong): c_ulong;
extern proc  mysql_real_escape_string_quote(to: c_ptr(c_char), from: c_string, length: c_ulong, quote: c_char):c_ulong;
extern proc  mysql_debug(debug: c_string): c_void_ptr;
extern proc  myodbc_remove_escape(name: c_ptr(c_char)): c_void_ptr;
extern proc  mysql_thread_safe(): c_uint;
extern proc  mysql_embedded(_my_bool: my_bool): my_bool;
extern proc  mysql_read_query_result(mysql: c_ptr(MYSQL)): my_bool;
extern proc  mysql_reset_connection(mysql: c_ptr(MYSQL)): c_int;
extern "struct st_mysql_bind" record st_mysql_bind {
}

extern record MYSQL_BIND {
}

extern "struct st_mysql_stmt_extension" record st_mysql_stmt_extension {
}

extern record MYSQL_STMT {
}

extern proc  mysql_stmt_init(_MYSQL_STMT: MYSQL_STMT, mysql: c_ptr(MYSQL)): c_ptr(MYSQL_STMT);
extern proc  mysql_stmt_prepare(query: c_string, length: c_ulong): c_int;
extern proc  mysql_stmt_execute(stmt: c_ptr(MYSQL_STMT)): c_int;
extern proc  mysql_stmt_fetch(stmt: c_ptr(MYSQL_STMT)): c_int;
extern proc  mysql_stmt_fetch_column(bind_arg: c_ptr(MYSQL_BIND), column: c_uint, offset: c_ulong): c_int;
extern proc  mysql_stmt_store_result(stmt: c_ptr(MYSQL_STMT)): c_int;
extern proc  mysql_stmt_param_count(stmt: c_ptr(MYSQL_STMT)): c_ulong;
extern proc  mysql_stmt_attr_set(stmt: c_ptr(MYSQL_STMT), attr___type:  enum_stmt_attr_type, attr: c_void_ptr): my_bool;
extern proc  mysql_stmt_attr_get(stmt: c_ptr(MYSQL_STMT), attr___type:  enum_stmt_attr_type, attr: c_void_ptr): my_bool;
extern proc  mysql_stmt_bind_param(stmt: c_ptr(MYSQL_STMT), bnd: c_ptr(MYSQL_BIND)): my_bool;
extern proc  mysql_stmt_bind_result(stmt: c_ptr(MYSQL_STMT), bnd: c_ptr(MYSQL_BIND)): my_bool;
extern proc  mysql_stmt_close(stmt: c_ptr(MYSQL_STMT)): my_bool;
extern proc  mysql_stmt_reset(stmt: c_ptr(MYSQL_STMT)): my_bool;
extern proc  mysql_stmt_free_result(stmt: c_ptr(MYSQL_STMT)): my_bool;
extern proc  mysql_stmt_send_long_data(stmt: c_ptr(MYSQL_STMT), param_number: c_uint, data: c_string, length: c_ulong): my_bool;
extern proc  mysql_stmt_result_metadata(stmt: c_ptr(MYSQL_STMT)): c_ptr(MYSQL_RES);
extern proc  mysql_stmt_param_metadata(stmt: c_ptr(MYSQL_STMT)): c_ptr(MYSQL_RES);
extern proc  mysql_stmt_errno(stmt: c_ptr(MYSQL_STMT)): c_uint;
extern proc  mysql_stmt_error(stmt: c_ptr(MYSQL_STMT)): c_string;
extern proc  mysql_stmt_sqlstate(stmt: c_ptr(MYSQL_STMT)): c_string;
extern proc  mysql_stmt_row_seek(stmt: c_ptr(MYSQL_STMT), offset: MYSQL_ROW_OFFSET): MYSQL_ROW_OFFSET;
extern proc  mysql_stmt_row_tell(stmt: c_ptr(MYSQL_STMT)): MYSQL_ROW_OFFSET;
extern proc  mysql_stmt_data_seek(offset: my_ulonglong): c_void_ptr;
extern proc  mysql_stmt_num_rows(stmt: c_ptr(MYSQL_STMT)): my_ulonglong;
extern proc  mysql_stmt_affected_rows(stmt: c_ptr(MYSQL_STMT)): my_ulonglong;
extern proc  mysql_stmt_insert_id(stmt: c_ptr(MYSQL_STMT)): my_ulonglong;
extern proc  mysql_stmt_field_count(stmt: c_ptr(MYSQL_STMT)): c_uint;
extern proc  mysql_commit(mysql: c_ptr(MYSQL)): my_bool;
extern proc  mysql_rollback(mysql: c_ptr(MYSQL)): my_bool;
extern proc  mysql_autocommit(mysql: c_ptr(MYSQL), auto_mode: my_bool): my_bool;
extern proc  mysql_more_results(mysql: c_ptr(MYSQL)): my_bool;
extern proc  mysql_next_result(mysql: c_ptr(MYSQL)): c_int;
extern proc  mysql_stmt_next_result(stmt: c_ptr(MYSQL_STMT)): c_int;
extern proc  mysql_close(sock: c_ptr(MYSQL)): c_void_ptr;

}// Mysql Native
//Helpers
extern proc __get_mysql_row_by_number(row: MYSQL_ROW,i: c_int): c_string;

extern proc __get_mysql_field_name_by_number(fields: c_ptr(MYSQL_FIELD),i: c_int): c_string;

}