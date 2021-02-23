#ifndef __MYSQL_HELPER_H
    #define __MYSQL_HELPER_H
//    #include <my_global.h> (can't find this file anywhere)
    #include <mysql.h>
    #include <stdio.h>
    #include <string.h>

    const char* __get_mysql_field_val_by_number(MYSQL_ROW row, int idx);
    const char* __get_mysql_field_name_by_number(MYSQL_FIELD *fields, int idx);
    int __get_mysql_field_number_by_name(MYSQL_FIELD *fields, const char* field_name);
    const char* __get_mysql_field_val_by_name(MYSQL_ROW row, MYSQL_FIELD *fields, const char* field_name);
    int __get_mysql_field_type_by_idx(MYSQL_FIELD *fields, int idx);
#endif