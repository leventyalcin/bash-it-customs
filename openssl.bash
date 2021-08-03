#!/usr/bin/env bash

openssl_verify_keypair() {
    local __key
    local __crt
    local __crt_fprint
    local __key_fprint

    [[ -f "${1}.key" ]] && __key="${1}.key"
    [[ -z "${__key:-}" ]] && [[ -f "${1}.pem" ]] && __key="${1}.pem"
    if [[ -z "${__key:-}" ]]; then
        echo >&2 "SSL key is not exist"
        return 2
    fi

    [[ -f "${1}.crt" ]] && __crt="${1}.crt"
    [[ -z "${__crt:-}" ]] && [[ -f "${1}.cer" ]] && __crt="${1}.cer"
    if [[ -z "${__crt:-}" ]]; then
        echo >&2 "SSL cert is not exist"
        return 2
    fi

    __crt_fprint=$(openssl x509 -noout -modulus -in "${__crt}" | openssl md5)
    __key_fprint=$(openssl rsa -noout -modulus -in "${__key}" | openssl md5)
    if [[ "${__crt_fprint}" != "${__key_fprint}" ]]; then
        echo >&2 "Fingerprints are not matching"
        echo "KEY=${__key_fprint}"
        echo "CRT=${__crt_fprint}"
        return 1
    else
        echo "OK"
        return 0
    fi
}


openssl_print_enddate() {
    local __cert="$1"

    if [[ ! -f "$__cert" ]]; then
        echo >&2 "Cert is no exist"
        return 2
    fi
    date \
        --date="$(openssl x509 -enddate -noout -in "$__cert" | cut -d= -f 2)" \
        --iso-8601='minutes'
}

openssl_print_cert_cn() {
    local __cert="$1"

    if [[ ! -f "$__cert" ]]; then
        echo >&2 "Cert is no exist"
        return 2
    fi
    openssl x509 -noout -subject -in "$__cert" | cut -d= -f 3
}
