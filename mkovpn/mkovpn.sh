#!/bin/bash
# Generate OVPN files (single config w/ certs and keys) for OpenVPN
# from EasyRSA tool's pki folder output
#
# - Tool expects to be in easy-rsa's pki fodler ( after `easy-rsa init-pki` )
# - outputs to ovpn-out folder
# Expected usage:
# $ # First install easy-rsa with your pkg manager
# $ mkdir ~/openvpn # new folder
# $ cd ~/openvpn
# $ cp -a /usr/share/easy-rsa/[0-9]/* .
# $ ./easyrsa init-pki
# $ ./easyrsa build-ca
# $ ./easyrsa gen-dh
# $ # Where <filename_base> is a regular name like "computer1"
# $ ./build-server-full <filename_base> [ cmd-opts ]
# $ ./build-client-full <filename_base> [ cmd-opts ]
# $ cd pki
# $ wget <this script>
# $ ./mkovpn.sh server vpn.server1.com 10.8.0.1
# $ ./mkovpn.sh client computer1 vpn.server1.com
# $ # Now you may distribute the files to your server and client
#
# Author: Michael Goodwin <xenithorb> / 2017-05-17
#
out_dir="./ovpn-out"
[[ ! -d "${out_dir}" ]] && mkdir "${out_dir}"

type="$1"
cipher="AES-256-GCM"
# This can be set lower for incompatible older clients, so they don't end up
# using Blowfish by default (64 bit, insecure)
cipher="AES-128-CBC"
ciphers="AES-256-GCM:AES-128-GCM:AES-256-CBC:AES-128-CBC"
port="1194"
shift

name="${1?:ERROR: Need certificate base name}"

if [[ $type == "server" ]]; then
	server="${1?:ERROR: Need server DNS}"
	subnet="${2?:ERROR: Need internal VPN subnet address, 10.8.0.0 maybe?}"
	name="${server}"
	out_format="${server}.conf"
elif [[ $type == "client" ]]; then
	server="${2?:ERROR: Need server DNS}"
	out_format="${name}-${server}.ovpn"
fi

format_cert() {
	local type="$1" file="$2" ssl_cmd="x509"
	[[ "$type" == "key" ]] && ssl_cmd="rsa"
	[[ "$type" == "dh" ]] && ssl_cmd="dh"
	printf '<%s>\n%s\n</%s>\n' \
		"$type" \
		"$( openssl "${ssl_cmd}" -in "${file}" )" \
		"$type"
}

print_certs() {
	local name="$1"
	format_cert ca "ca.crt"
	format_cert cert "issued/${name}.crt"
	format_cert key "private/${name}.key" || \
		{ echo "Key decrypted incorrectly" ; exit 1; } 1>&2
	[[ "${out_format}" =~ .conf$ ]] && \
		format_cert dh "dh.pem"
}

CONFIG_CLIENT_ONLY=(
	"client"
	"remote ${server} ${port}"
	"nobind"
	";allow-recursive-routing"
	"explicit-exit-notify 1"
	"resolv-retry infinite"
)

CONFIG_COMMON=(
	"proto udp"
	"dev tun"
	"persist-key"
	"persist-tun"
	";comp-lzo"
	"verb 3"
	"cipher ${cipher}"
	""
)

CONFIG_SERVER_ONLY=(
	"server ${subnet} 255.255.255.0"
	";push \"route 192.168.1.0 255.255.255.0\""
	"push \"redirect-gateway def1 bypass-dhcp block-local\""
	"push \"dhcp-option DNS ${subnet%\.*}.1\""
	"ncp-ciphers ${ciphers}"
	";client-to-client"
	"mute 10"
	"keepalive 5 30"
)

print_opts() {
	local name="$1" server="$2" type="$3"
	[[ "$type" == "client" ]] && printf "%s\n" "${CONFIG_CLIENT_ONLY[@]}"
	[[ "$type" == "server" ]] && printf "%s\n" "${CONFIG_SERVER_ONLY[@]}"
	printf "%s\n" "${CONFIG_COMMON[@]}"
}

print_config() {
	local name="$1" server="$2" type="$3"
	print_opts  "$name" "$server" "$type"
	print_certs "$name"
}

print_config "$name" "$server" "$type" | tee "${out_dir}/${out_format}" > /dev/null
