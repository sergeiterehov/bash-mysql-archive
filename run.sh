#!/bin/bash

source ./config.sh

function __make_archive
{

    # Нижняя граница дампа
    LIMIT_BOTTOM="$(
        ssh ${DB_DIST_SSH} \
            mysql \
                --user="'${DB_DIST_USER}'" --password="'${DB_DIST_PASSWORD}'" \
                --database="${DB_DIST_DATABASE}" \
                --execute="'select id from queue order by id desc limit 1;'" \
        | tail -n 1
    )"

    if [[ ${LIMIT_BOTTOM} = "" ]]
    then
        LIMIT_BOTTOM=0
    fi

    SQL_WHERE="id > ${LIMIT_BOTTOM} and id < ${LIMIT_TOP}"
    SQL="${SQL_WHERE} limit ${PART_LIMIT}"

    DUMP_COUNT="$(
        mysql \
            --user="${DB_SOURCE_USER}" --password="${DB_SOURCE_PASSWORD}" \
            --database="${DB_SOURCE_DATABASE}" \
            --execute="select count(id) from queue where ${SQL_WHERE};" \
        | tail -n 1
    )"

    if [[ ${DUMP_COUNT} = "0" ]]
    then
        echo "Creating archive complete!"
        exit
    fi

    echo "Dump condition: \"${SQL_WHERE}\" => ${DUMP_COUNT} found"

    mysqldump \
        -u${DB_SOURCE_USER} -p"${DB_SOURCE_PASSWORD}" -h localhost \
        --no-create-info \
        --databases ${DB_SOURCE_DATABASE} --tables ${DB_SOURCE_TABLE} \
        --where="${SQL}" \
    | ssh ${DB_DIST_SSH} \
        mysql \
            -u${DB_DIST_USER} -p"'${DB_DIST_PASSWORD}'" -h localhost \
            ${DB_DIST_DATABASE}

    # Repeat
    __make_archive

}

function __main
{
    echo "[BEGIN]"

    echo "Dropping on part by ${PART_LIMIT}"
    echo "Last record condition: \"${LAST_CREATED_AT}\""

    # Верхняя граница дампа
    LIMIT_TOP="$(
        mysql \
            --user="${DB_SOURCE_USER}" --password="${DB_SOURCE_PASSWORD}" \
            --database="${DB_SOURCE_DATABASE}" \
            --execute="select id from queue where created_at <= unix_timestamp(${LAST_CREATED_AT}) order by id desc limit 1;" \
        | tail -n 1
    )"

    if [[ ${LIMIT_TOP} = "" ]]
    then
        echo "Nothing to archivate!"
    else
        __make_archive
    fi

    echo "[END]"

}

# Точка входа

ERROR_LOG="$(mktemp)"

__main 2> ${ERROR_LOG}

echo -e "\e[31mError log: ${ERROR_LOG}\e[0m"