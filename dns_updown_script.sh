#!/bin/ash
# Copyright (c) 2017 Michael Goodwin
# 
# MIT License
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
set -x 
export > /tmp/script_env
exec > /tmp/script_out 2>&1 

PID_FILE=/var/run/dnsmasq/dnsmasq.pid 
RESOLV_FILE=/tmp/resolv.conf.auto 

reload_dnsmasq() {
        if [[ -f "${PID_FILE}" ]]; then
                kill -HUP $( cat < "$PID_FILE" )
        fi
}

up() {
        local resolv_file="$RESOLV_FILE"
        local current_resolv="$( cat < "${resolv_file}" )"
        local new_dns="$( export | awk '/dhcp-option DNS/i { sub(/[\"'\'']$/,""); print "nameserver",$NF }' )"

        # Backup current resolv.conf
        echo "${current_resolv}" > "${resolv_file}.bak"

        # Remove nameservers from current resolv.conf.auto and write new dns
        {
                echo "${current_resolv}" | grep -v "^nameserver";
                echo "${new_dns}";
        } > "${resolv_file}"

        reload_dnsmasq
}

down() {
        # Move old resolv.conf.auto back
        local resolv_file=/tmp/resolv.conf.auto
        [[ -f ${resolv_file}.bak ]] && mv "${resolv_file}.bak" "${resolv_file}"

        reload_dnsmasq
}

$script_type

exit 0