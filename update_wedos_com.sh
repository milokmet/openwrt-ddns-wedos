#!/bin/sh

# WEDOS.COM DDNS SCRIPT
# Requires coreutils-sha1sum and curl
# opkg install coreutils-sha1sum curl

[ -z "$CURL" ] && [ -z "$CURL_SSL" ] && write_log 14 "wedos.com communication require cURL with SSL support. Please install"
[ -z "$domain" ] && write_log 14 "Service section not configured correctly! Missing 'domain'"
[ -z "$username" ] && write_log 14 "Service section not configured correctly! Missing 'username'"
[ -z "$password" ] && write_log 14 "Service section not configured correctly! Missing 'password'"

. /usr/share/libubox/jshn.sh

write_log 0 "wedos.com ddns script started"

local __SUBDOMAIN __MAINDOMAIN __LOGINURL __RECORDID __RECORDTTL __RDTYPE API

API='https://api.wedos.com/wapi/json'
__SUBDOMAIN=$(echo $domain | sed -e 's/[^\.]*\.[^\.]*$//' -e 's/\.$//' )
__MAINDOMAIN=$(echo $domain | sed -e "s/${__SUBDOMAIN}\.//" )

# create authentication token
passhash=$(printf "%s" "$password" | sha1sum | cut -d' ' -f1)
hour=$(date +'%H')
auth=$(printf "%s" "${username}${passhash}${hour}" | sha1sum | cut -d' ' -f1)

# Fetching DNS records list
json_init
json_add_object "request"
json_add_string "user" ${username}
json_add_string "auth" ${auth}
json_add_string "command" "dns-rows-list"
json_add_object "data"
json_add_string "domain" "${__MAINDOMAIN}"

data=$(json_dump)
response=$($CURL -q --data-urlencode "request=${data}" -X POST $API 2>/dev/null)

json_load "${response}"
if json_is_a response object && \
	json_select response && \
	json_is_a data object && \
	json_select data && \
	json_is_a row array
then
	json_select "row"
	i=1
	while json_is_a ${i} "object" ; do
		json_select "${i}"
		json_get_var "name" "name"
		if [ "$name" == "$__SUBDOMAIN" ]; then
			json_get_var "__RECORDID" "ID"
			json_get_var "__RECORDTTL" "ttl"
			json_get_var "__RDTYPE" "rdtype"
			write_log 0 "Found record id: ${__RECORDID}"
			break;
		fi
		json_close_object
		i=$(($i+1))
	done
	json_close_object
	json_close_object
	json_close_object
fi

if [ -z "${__RECORDID}" ]; then
	write_log 14 "domain record not found"
	return 1
fi

# CREATING UPDATE DATA
json_init
json_add_object "request"
json_add_string "user" "${username}"
json_add_string "auth" ${auth}
json_add_string "command" "dns-row-update"
json_add_object "data"
json_add_string "row_id" "${__RECORDID}"
json_add_string "ttl" "${__RECORDTTL}"
json_add_string "rdata" "${__IP}"
json_add_string "domain" "${__MAINDOMAIN}"

data=$(json_dump)
response=$($CURL -q --data-urlencode "request=${data}" -X POST $API 2>/dev/null)

json_load "${response}"
if json_is_a response object && \
	json_select response && \
	json_is_a result string && \
	json_get_var "result" "result" && \
	[ "${result}" != "OK" ]
then
	write_log 14 "Can't update the domain. Result: ${result}"
	return 1
fi

json_init
json_add_object "request"
json_add_string "user" "${username}"
json_add_string "auth" "${auth}"
json_add_string command "dns-domain-commit"
json_add_object "data"
json_add_string "name" "${__MAINDOMAIN}"

data=$(json_dump)
response=$($CURL -q --data-urlencode "request=${data}" -X POST $API 2>/dev/null)

json_load "$response"
if json_is_a response object && \
	json_select response && \
	json_is_a result string && \
	json_get_var "result" "result" && \
	[ "${result}" != "OK" ]
then
	write_log 14 "Can't commit the changes. Result: ${result}"
	return 1      
fi

write_log 0 "wedos.comddns script finished without errors"
return 0
