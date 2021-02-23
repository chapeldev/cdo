#include "mysql_helper.h"

const char* __get_mysql_field_val_by_number(MYSQL_ROW row, int idx) {
    return (const char*) row[idx];
}

const char* __get_mysql_field_name_by_number(MYSQL_FIELD *fields, int idx) {
    return (const char*) fields[idx].name;
}

int __get_mysql_field_number_by_name(MYSQL_FIELD *fields, const char* field_name) {
    int fieldNumber = 0;
    while (strcmp(fields[fieldNumber].name, field_name) != 0) {
        fieldNumber++;
    }
    return fieldNumber;
}

const char* __get_mysql_field_val_by_name(MYSQL_ROW row, MYSQL_FIELD *fields, const char* field_name) {
    int fieldNumber = __get_mysql_field_number_by_name(fields, field_name);
    return (const char*) row[fieldNumber];
}

int __get_mysql_field_type_by_idx(MYSQL_FIELD *fields, int idx) {
    // NOTE: Here, we could just return fields[i].type
    // However, as the enum values are not known, it may cause
    // problems or inconvenience on the Chapel side, if the enum
    // values are unpredictable, get changed
    // or new field types are added

    int fieldType = -1;

    switch (fields[idx].type) {
        case MYSQL_TYPE_TINY:
            fieldType = 0;
            break;
        
        case MYSQL_TYPE_SHORT:
            fieldType = 1;
            break;

        case MYSQL_TYPE_LONG:
            fieldType = 2;
            break;

        case MYSQL_TYPE_INT24:
            fieldType = 3;
            break;

        case MYSQL_TYPE_LONGLONG:
            fieldType = 4;
            break;

        case MYSQL_TYPE_DECIMAL:
            fieldType = 5;
            break;

        case MYSQL_TYPE_NEWDECIMAL:
            fieldType = 6;
            break;

        case MYSQL_TYPE_FLOAT:
            fieldType = 7;
            break;

        case MYSQL_TYPE_DOUBLE:
            fieldType = 8;
            break;

        case MYSQL_TYPE_BIT:
            fieldType = 9;
            break;

        case MYSQL_TYPE_TIMESTAMP:
            fieldType = 10;
            break;

        case MYSQL_TYPE_DATE:
            fieldType = 11;
            break;

        case MYSQL_TYPE_TIME:
            fieldType = 12;
            break;

        case MYSQL_TYPE_DATETIME:
            fieldType = 13;
            break;

        case MYSQL_TYPE_YEAR:
            fieldType = 14;
            break;

        case MYSQL_TYPE_STRING:
            fieldType = 15;
            break;

        case MYSQL_TYPE_VAR_STRING:
            fieldType = 16;
            break;

        case MYSQL_TYPE_BLOB:
            fieldType = 17;
            break;

        case MYSQL_TYPE_SET:
            fieldType = 18;
            break;

        case MYSQL_TYPE_ENUM:
            fieldType = 19;
            break;

        case MYSQL_TYPE_GEOMETRY:
            fieldType = 20;
            break;

        case MYSQL_TYPE_NULL:
            fieldType = 21;
            break;

        default:
            fieldType = 22;
            break;
    }

    return fieldType;
}