#!/usr/bin/env bash

# Every test runs in its own subshell, so its EXIT trap intentionally captures
# the test-specific temporary path when the trap is installed.
# shellcheck disable=SC2064

set -u
set -o pipefail

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TEST_ROOT
readonly WIFI_SCRIPT="$TEST_ROOT/other_authors/wifi.sh"

passed=0
failed=0

run_test() {
    local name="$1"
    shift

    if ("$@"); then
        printf 'PASS %s\n' "$name"
        passed=$((passed + 1))
    else
        printf 'FAIL %s\n' "$name"
        failed=$((failed + 1))
    fi
}

source_wifi() {
    export WIFI_LIBRARY_ONLY=1
    export WPA_CONF="$1"
    export __nodialog=1
    # shellcheck source=../other_authors/wifi.sh
    source "$WIFI_SCRIPT"
}

test_syntax() {
    "$BASH" -n "$WIFI_SCRIPT"
}

test_library_mode_preserves_exit_trap() {
    local temp_dir before after

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    before=$(trap -p EXIT)
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    after=$(trap -p EXIT)

    [[ "$before" == "$after" ]]
}

test_console_output_does_not_expand_untrusted_escapes() {
    local temp_dir output

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1

    output=$(printMsgs console $'SSID \e[31m literal \\\\e[32m \\\\x41 \\\\c end\\nNext')
    [[ "$output" == *'\x1B[31m'* ]] || return 1
    [[ "$output" == *'\e[32m'* ]] || return 1
    [[ "$output" == *'\x41'* ]] || return 1
    [[ "$output" == *'\c end'* ]] || return 1
    [[ "$output" == *$'end\nNext' ]] || return 1

    detect_interface() { return 0; }
    current_ssid() { printf $'Unsafe\e[31mSSID\n'; }
    current_ip() { printf '192.0.2.90\n'; }
    default_gateway() { return 0; }
    ping_once() { return 1; }
    dns_lookup_ok() { return 1; }
    output=$(main --health) || return 1
    [[ "$output" == *'SSID: Unsafe\x1B[31mSSID'* ]] || return 1
    [[ "$output" != *$'\e'* ]]
}

test_connection_summary_includes_radio_metrics() {
    local temp_dir output

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    printf 'country=US\n' > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1

    INTERFACE=wlan0
    current_ssid() { printf 'Test Network\n'; }
    current_ip() { printf '192.0.2.90\n'; }
    default_gateway() { printf '192.0.2.1\n'; }
    ping_once() { return 0; }
    dns_lookup_ok() { return 0; }
    iw() {
        cat <<'EOF'
Connected to 00:11:22:33:44:55 (on wlan0)
	SSID: Test Network
	freq: 5180
	RX: 1048576 bytes (1000 packets)
	TX: 2048 bytes (20 packets)
	signal: -61 dBm
	rx bitrate: 144.4 MBit/s
	tx bitrate: 130.0 MBit/s
EOF
    }
    interface_counter() {
        case "$1" in
            rx_bytes) printf '1048576' ;;
            tx_bytes) printf '2048' ;;
            rx_errors) printf '1' ;;
            tx_errors) printf '2' ;;
            rx_dropped) printf '3' ;;
            tx_dropped) printf '4' ;;
            *) return 1 ;;
        esac
    }

    output=$(connection_health_report) || return 1
    [[ "$output" == *"Country: US"* ]] || return 1
    [[ "$output" == *"Signal: -61 dBm (Good)"* ]] || return 1
    [[ "$output" == *"Frequency: 5180 MHz"* ]] || return 1
    [[ "$output" == *"RX link rate: 144.4 MBit/s"* ]] || return 1
    [[ "$output" == *"TX link rate: 130.0 MBit/s"* ]] || return 1
    [[ "$output" == *"Traffic since interface up: RX 1.0 MiB, TX 2.0 KiB"* ]] || return 1
    [[ "$output" == *"Errors/dropped packets: RX 1/3, TX 2/4"* ]] || return 1
    [[ "$output" == *"DNS lookup: OK"* ]]
}

test_connection_summary_degrades_without_optional_metric_tools() {
    local temp_dir output

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1

    current_ssid() { return 0; }
    current_ip() { return 0; }
    default_gateway() { return 0; }
    ping_once() { return 1; }
    interface_counter() { return 1; }
    command_exists() {
        case "$1" in
            iw|getent|nslookup) return 1 ;;
            *) command -v "$1" >/dev/null 2>&1 ;;
        esac
    }

    output=$(connection_health_report) || return 1
    [[ "$output" == *"Radio link: metrics unavailable (iw not installed)"* ]] || return 1
    [[ "$output" == *"Signal: (unavailable)"* ]] || return 1
    [[ "$output" == *"DNS lookup: not tested (resolver tool unavailable)"* ]]
}

test_dns_lookup_requires_an_answer_address() {
    local temp_dir output

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1

    current_ssid() { printf 'Test Network\n'; }
    current_ip() { printf '192.0.2.90\n'; }
    default_gateway() { printf '192.0.2.1\n'; }
    ping_once() { return 0; }
    wireless_link_report() { printf 'Radio link: associated\n'; }
    command_exists() {
        [[ "$1" == "nslookup" ]]
    }
    nslookup() {
        cat <<'EOF'
Server:    192.0.2.1
Address 1: 192.0.2.1
nslookup: can't resolve 'misterfpga.org'
EOF
        return 0
    }

    output=$(connection_health_report) || return 1
    [[ "$output" == *"DNS lookup: failed"* ]] || return 1

    nslookup() {
        cat <<'EOF'
Server:    192.0.2.1
Address 1: 192.0.2.1

Name:      misterfpga.org
Address 1: 198.51.100.42 misterfpga.org
EOF
        return 0
    }
    dns_lookup_ok
}

test_failed_dns_resolver_is_not_reported_as_missing() {
    local temp_dir output

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1

    current_ssid() { printf 'Test Network\n'; }
    current_ip() { printf '192.0.2.90\n'; }
    default_gateway() { printf '192.0.2.1\n'; }
    ping_once() { return 0; }
    wireless_link_report() { printf 'Radio link: associated\n'; }
    command_exists() {
        [[ "$1" == "getent" ]]
    }
    getent() {
        return 2
    }

    output=$(connection_health_report) || return 1
    [[ "$output" == *"DNS lookup: failed"* ]] || return 1
    [[ "$output" != *"resolver tool unavailable"* ]]
}

test_main_menu_prioritizes_connection_actions() {
    local temp_dir menu_args output

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1

    current_ssid() { printf 'Test Network\n'; }
    current_ip() { printf '192.0.2.90\n'; }
    capture_dialog() {
        printf '%s\n' "$@" > "$temp_dir/menu_args"
        return 1
    }

    main_menu || return 1
    menu_args=$(< "$temp_dir/menu_args")
    [[ "$menu_args" == *$'1\nScan and Connect\n2\nConnect to Saved WiFi\n3\nDisconnect from WiFi\n4\nSaved Networks\n'* ]] || return 1
    [[ "$menu_args" != *"Show WiFi status"* ]] || return 1

    detect_interface() { return 0; }
    connection_health_report() { printf 'shared connection summary\n'; }
    output=$(main --status) || return 1
    [[ "$output" == "shared connection summary" ]]
}

test_country_update_is_atomic_and_preserves_globals() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    cat > "$temp_dir/wpa_supplicant.conf" <<'EOF'
# custom setting
ctrl_interface=DIR=/custom GROUP=wheel
update_config=0
ap_scan=2
fast_reauth=0
blob-base64-country-test={
country=GB
country=
}
country=US
country=GB
network={
    ssid="Keep Me"
    psk="password"
}
network={
    ssid="Commented" # valid trailing comment
    key_mgmt=NONE
}
network={
    ssid=410942
    key_mgmt=NONE
}
network={
    ssid="A\x09B"
    key_mgmt=NONE
}
EOF
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    sync() { :; }
    printMsgs() { :; }

    set_country_code CA || return 1
    grep -qx 'country=CA' "$WPA_CONF" || return 1
    [[ $(grep -c '^country=GB$' "$WPA_CONF") -eq 1 ]] || return 1
    [[ $(grep -c '^country=$' "$WPA_CONF") -eq 1 ]] || return 1
    [[ $(get_country_code) == "CA" ]] || return 1
    [[ -z $(wpa_conf_validation_error) ]] || return 1
    grep -qx 'ctrl_interface=DIR=/custom GROUP=wheel' "$WPA_CONF" || return 1
    grep -qx 'update_config=0' "$WPA_CONF" || return 1
    grep -qx 'ap_scan=2' "$WPA_CONF" || return 1
    grep -qx 'fast_reauth=0' "$WPA_CONF"
}

test_repair_preserves_valid_content() {
    local temp_dir error

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    cat > "$temp_dir/wpa_supplicant.conf" <<'EOF'
# custom setting
ctrl_interface=DIR=/custom GROUP=wheel
update_config=0
ap_scan=2
country=USA
blob-base64-client/cert={ # preserved opaque block
YWJjZA==
} # end blob
cred={ # preserved credential block
    realm="example.com"
    username="user"
} # end cred
network={ # valid network
    ssid="Keep#Me"
    psk="password#123"
} # end network
network = {
    ssid="Drop Invalid Header"
    key_mgmt=NONE
}
network={
    ssid="Drop Bad Key"
    psk="broken
}
network={
    ssid="Drop Me"
    psk="broken"
EOF
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    sync() { :; }
    printMsgs() { :; }

    repair_wpa_conf || return 1
    grep -qx 'country=US' "$WPA_CONF" || return 1
    grep -qx '# custom setting' "$WPA_CONF" || return 1
    grep -qx 'ctrl_interface=DIR=/custom GROUP=wheel' "$WPA_CONF" || return 1
    grep -qx 'update_config=0' "$WPA_CONF" || return 1
    grep -qx 'ap_scan=2' "$WPA_CONF" || return 1
    grep -Fqx 'blob-base64-client/cert={ # preserved opaque block' "$WPA_CONF" || return 1
    grep -qx 'YWJjZA==' "$WPA_CONF" || return 1
    grep -Fqx 'cred={ # preserved credential block' "$WPA_CONF" || return 1
    grep -qx '    realm="example.com"' "$WPA_CONF" || return 1
    grep -Fq 'ssid="Keep#Me"' "$WPA_CONF" || return 1
    grep -Fq 'psk="password#123"' "$WPA_CONF" || return 1
    ! grep -q 'Drop Invalid Header' "$WPA_CONF" || return 1
    ! grep -q 'Drop Bad Key' "$WPA_CONF" || return 1
    ! grep -q 'Drop Me' "$WPA_CONF" || return 1
    error=$(wpa_conf_validation_error)
    [[ -z "$error" ]]
}

test_validator_rejects_empty_and_unterminated_ssids() {
    local temp_dir empty_error unterminated_error psk_error opaque_error invalid_header_error

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1

    cat > "$temp_dir/empty.conf" <<'EOF'
network={
    ssid=""
}
EOF
    cat > "$temp_dir/unterminated.conf" <<'EOF'
network={
    ssid="broken
}
EOF
    cat > "$temp_dir/opaque.conf" <<'EOF'
blob-base64-client/cert={ # valid trailing comment
YWJjZA==
} # valid trailing comment
cred={ # valid trailing comment
    realm="example.com"
} # valid trailing comment
network={ # valid trailing comment
    ssid="Hash#Commented" # valid trailing comment
    psk="password#123" # valid trailing comment
} # valid trailing comment
EOF
    cat > "$temp_dir/bad-psk.conf" <<'EOF'
network={
    ssid="Broken Key"
    psk="unterminated
}
EOF
    cat > "$temp_dir/invalid-header.conf" <<'EOF'
network = {
    ssid="Invalid Header"
    key_mgmt=NONE
}
EOF
    empty_error=$(wpa_conf_validation_error "$temp_dir/empty.conf")
    unterminated_error=$(wpa_conf_validation_error "$temp_dir/unterminated.conf")
    psk_error=$(wpa_conf_validation_error "$temp_dir/bad-psk.conf")
    opaque_error=$(wpa_conf_validation_error "$temp_dir/opaque.conf")
    invalid_header_error=$(wpa_conf_validation_error "$temp_dir/invalid-header.conf")

    [[ "$empty_error" == *"empty SSID"* ]] || return 1
    [[ "$unterminated_error" == *"invalid or unterminated SSID"* ]] || return 1
    [[ "$psk_error" == *"unterminated quoted value"* ]] || return 1
    [[ "$invalid_header_error" == *"invalid config block header"* ]] || return 1
    [[ -z "$opaque_error" ]]
}

test_escaped_ssid_removal_is_exact() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    cat > "$temp_dir/wpa_supplicant.conf" <<'EOF'
country=US
network={
    ssid="A"B\C" # quotes and backslashes are literal
    psk="password#123"
}
network={
    ssid="Keep Me"
    psk="password"
}
network={
    ssid=P"Print\x23Net"
    key_mgmt=NONE
}
network={
    ssid="Commented" # valid trailing comment
    key_mgmt=NONE
}
network={
    ssid=410942
    key_mgmt=NONE
}
network={
    ssid="A\x09B"
    key_mgmt=NONE
}
EOF
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    sync() { :; }
    printMsgs() { :; }

    remove_network_by_ssid 'A"B\C' || return 1
    ! grep -Fq 'ssid="A"B\C"' "$WPA_CONF" || return 1
    grep -q 'ssid="Keep Me"' "$WPA_CONF" || return 1
    saved_networks | grep -Fqx $'1\tPrint#Net\t5072696e74234e6574' || return 1
    remove_network_by_ssid 'Print#Net' || return 1
    ! grep -Fq 'Print\x23Net' "$WPA_CONF" || return 1
    saved_networks | grep -Fqx $'1\tCommented\t436f6d6d656e746564' || return 1
    [[ $(saved_networks | grep -F $'\tA\\x09B\t' | wc -l) -eq 2 ]] || return 1
    remove_network_by_ssid 'A\x09B' 410942 || return 1
    ! grep -qx '    ssid=410942' "$WPA_CONF" || return 1
    grep -Fq 'ssid="A\x09B"' "$WPA_CONF" || return 1
    if wpa_hex_to_string 410942 >/dev/null; then
        return 1
    fi
    append_network_config open Commented "" 0 || return 1
    [[ $(grep -c '^    ssid=436f6d6d656e746564$' "$WPA_CONF") -eq 1 ]] || return 1
    ! grep -Fq 'ssid="Commented"' "$WPA_CONF" || return 1
    remove_network_by_ssid Commented || return 1
    ! grep -q '436f6d6d656e746564' "$WPA_CONF"
}

test_failed_wpa_generation_preserves_config() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    cat > "$temp_dir/wpa_supplicant.conf" <<'EOF'
country=US
network={
    ssid="Existing"
    psk="working-password"
}
EOF
    cp "$temp_dir/wpa_supplicant.conf" "$temp_dir/before.conf" || return 1
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    command_exists() { [[ "$1" == "wpa_passphrase" ]]; }
    wpa_passphrase() { return 9; }
    sync() { :; }

    if append_network_config wpa Existing password123 0; then
        return 1
    fi
    cmp -s "$temp_dir/before.conf" "$WPA_CONF"
}

test_wpa_key_validation_and_raw_psk() {
    local temp_dir raw_psk invalid_64 block generated_psk

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    command_exists() { return 1; }
    raw_psk=$(printf 'a%.0s' {1..64})
    invalid_64=$(printf 'g%.0s' {1..64})

    if network_block_for_wpa Test short 0 >/dev/null; then
        return 1
    fi
    if network_block_for_wpa Test "$invalid_64" 0 >/dev/null; then
        return 1
    fi
    block=$(network_block_for_wpa 'A"B\C#D' "$raw_psk" 0) || return 1
    printf '%s\n' "$block" | grep -qx '    ssid=4122425c432344' || return 1
    printf '%s\n' "$block" | grep -qx "    psk=$raw_psk" || return 1
    block=$(network_block_for_wpa Test 'pass#wo"rd\' 0) || return 1
    printf '%s\n' "$block" | grep -Fqx '    psk="pass#wo"rd\"' || return 1

    generated_psk=$(printf 'b%.0s' {1..64})
    command_exists() { [[ "$1" == "wpa_passphrase" ]]; }
    wpa_passphrase() {
        cat <<EOF
network={
    ssid="unsafe formatter output"
    #psk="password123"
    psk=$generated_psk
}
EOF
    }
    block=$(network_block_for_wpa 'A"B\C#D' password123 0) || return 1
    printf '%s\n' "$block" | grep -qx '    ssid=4122425c432344' || return 1
    printf '%s\n' "$block" | grep -qx "    psk=$generated_psk" || return 1
    ! printf '%s\n' "$block" | grep -q 'unsafe formatter output'
}

test_failed_atomic_move_preserves_config() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    cat > "$temp_dir/wpa_supplicant.conf" <<'EOF'
country=US
network={
    ssid="Existing"
    psk="working-password"
}
EOF
    cp "$temp_dir/wpa_supplicant.conf" "$temp_dir/before.conf" || return 1
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    printMsgs() { :; }
    mv() { return 1; }

    if set_country_code CA; then
        return 1
    fi
    cmp -s "$temp_dir/before.conf" "$WPA_CONF" || return 1
    [[ -z $(find "$temp_dir" -name '.wpa_supplicant.conf.tmp.*' -print -quit) ]]
}

test_wep_key_lengths_match_supplicant() {
    local temp_dir key index=0 invalid_58
    local valid_keys=(
        abcde
        abcdefghijklm
        abcdefghijklmnop
        0011223344
        00112233445566778899aabbcc
        00112233445566778899aabbccddeeff
    )
    local invalid_keys=(
        abcd
        abcdef
        abcdefghijkl
        abcdefghijklmn
        abcdefghijklmno
        abcdefghijklmnopq
    )

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    printf 'country=US\n' > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    sync() { :; }
    printMsgs() { :; }

    for key in "${valid_keys[@]}"; do
        append_network_config wep "Valid-$index" "$key" 0 || return 1
        index=$((index + 1))
    done
    [[ $(grep -c '^network={$' "$WPA_CONF") -eq 6 ]] || return 1

    invalid_58=$(printf 'a%.0s' {1..58})
    invalid_keys+=("$invalid_58")
    cp "$WPA_CONF" "$temp_dir/before-invalid.conf" || return 1
    for key in "${invalid_keys[@]}"; do
        if append_network_config wep Invalid "$key" 0; then
            return 1
        fi
        cmp -s "$temp_dir/before-invalid.conf" "$WPA_CONF" || return 1
    done
}

test_reconnect_has_headless_dependencies() {
    local temp_dir last_message=""

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    command_exists() {
        case "$1" in
            awk|grep|ip|iwgetid|od|sed|tr)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    }
    printMsgs() {
        last_message="$*"
    }

    require_tools reconnect || return 1
    if require_tools scan; then
        return 1
    fi
    [[ "$last_message" == *"iw"* ]]
}

test_saved_country_is_applied_without_prompt() {
    local temp_dir calls

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    printf 'country=US\n' > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    command_exists() { [[ "$1" == "iw" ]]; }
    printMsgs() { :; }
    sleep() { :; }
    capture_dialog() {
        : > "$temp_dir/dialog-called"
        return 1
    }
    iw() {
        printf '%s\n' "$*" >> "$temp_dir/iw-calls"
        if [[ "$1" == "reg" && "$2" == "get" ]]; then
            printf 'country US: DFS-FCC\n'
        fi
        return 0
    }

    prompt_country_code 0 || return 1
    [[ ! -e "$temp_dir/dialog-called" ]] || return 1
    calls=$(cat "$temp_dir/iw-calls")
    [[ "$calls" == *"reg set US"* && "$calls" == *"reg get"* ]]
}

test_supplicant_recovery_is_scoped_and_selection_checks_ok() {
    local temp_dir select_result="OK"

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    command_exists() { [[ "$1" == "wpa_cli" ]]; }
    wpa_cli() {
        printf '%s\n' "$*" >> "$temp_dir/wpa-calls"
        case "$*" in
            *" ping")
                printf 'PONG\n'
                ;;
            *" reconfigure"|*" reassociate")
                printf 'OK\n'
                ;;
            *" terminate")
                : > "$temp_dir/terminate-called"
                printf 'OK\n'
                ;;
        esac
        return 0
    }

    reload_wpa_supplicant || return 1
    [[ ! -e "$temp_dir/terminate-called" ]] || return 1

    wpa_cli() {
        case "$*" in
            *" list_networks")
                printf 'network id\tssid\tbssid\tflags\n7\tTarget\tany\t[CURRENT]\n8\tBackup\tany\t\n9\tA\\"B\\\\C#D\tany\t[DISABLED]\n'
                ;;
            *" select_network 7")
                printf '%s\n' "$select_result"
                : > "$temp_dir/select-called"
                ;;
            *" select_network 9")
                printf 'OK\n'
                : > "$temp_dir/escaped-select-called"
                ;;
            *" enable_network "*)
                printf '%s\n' "$*" >> "$temp_dir/enable-calls"
                printf 'OK\n'
                ;;
        esac
        return 0
    }
    select_target_network Target || return 1
    [[ -e "$temp_dir/select-called" ]] || return 1
    restore_network_enable_state || return 1
    grep -q 'enable_network 8' "$temp_dir/enable-calls" || return 1
    ! grep -q 'enable_network 9' "$temp_dir/enable-calls" || return 1
    : > "$temp_dir/enable-calls"
    select_target_network 'A"B\C#D' 4122425c432344 || return 1
    [[ -e "$temp_dir/escaped-select-called" ]] || return 1
    restore_network_enable_state || return 1
    grep -q 'enable_network 7' "$temp_dir/enable-calls" || return 1
    grep -q 'enable_network 8' "$temp_dir/enable-calls" || return 1

    select_result="FAIL"
    if select_target_network Target; then
        return 1
    fi

    command_exists() { return 1; }
    ! select_target_network Target
}

test_dhcp_prefers_dhcpcd_and_propagates_failure() {
    local temp_dir rc calls

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    command_exists() { [[ "$1" == "dhcpcd" || "$1" == "udhcpc" ]]; }
    run_with_timeout() {
        printf '%s\n' "$*" >> "$temp_dir/dhcp-calls"
        return 0
    }

    start_dhcp_lease_request || return 1
    calls=$(cat "$temp_dir/dhcp-calls")
    [[ "$calls" == *"dhcpcd -n $INTERFACE"* ]] || return 1
    [[ "$calls" != *"udhcpc"* ]] || return 1

    command_exists() { [[ "$1" == "udhcpc" ]]; }
    run_with_timeout() { return 7; }
    start_dhcp_lease_request
    rc=$?
    [[ "$rc" -eq 7 ]]
}

test_stale_ip_is_rejected_after_association_changes() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    export IPV4_WAIT_SECONDS=2
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    current_ssid() { printf 'OtherNetwork\n'; }
    current_ip() {
        : > "$temp_dir/current-ip-called"
        printf '192.0.2.44\n'
    }
    sleep() { :; }

    if wait_for_ipv4_lease ExpectedNetwork >/dev/null; then
        return 1
    fi
    [[ ! -e "$temp_dir/current-ip-called" ]]
}

test_hidden_network_remains_available_after_empty_scan() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    show_infobox() { :; }
    require_tools() { return 0; }
    detect_interface() { return 0; }
    prompt_country_code() { return 0; }
    list_wifi() { return 0; }
    printMsgs() { :; }
    capture_dialog() {
        if [[ "$*" == *"--inputbox"* ]]; then
            printf 'HiddenSSID\n'
        elif [[ "$*" == *"security type"* ]]; then
            printf 'open\n'
        else
            printf 'H\n'
        fi
    }
    append_network_config() {
        printf '%s\n' "$1" "$2" "$3" "$4" > "$temp_dir/appended"
    }
    apply_wifi_settings() {
        printf '%s\n' "$1" > "$temp_dir/applied"
    }

    connect_wifi || return 1
    [[ $(sed -n '1p' "$temp_dir/appended") == "open" ]] || return 1
    [[ $(sed -n '2p' "$temp_dir/appended") == "HiddenSSID" ]] || return 1
    [[ $(sed -n '4p' "$temp_dir/appended") == "1" ]] || return 1
    [[ $(cat "$temp_dir/applied") == "HiddenSSID" ]] || return 1
    [[ -z $(find "$temp_dir" -name 'wpa_supplicant.conf.rollback.*' -print -quit) ]]
}

test_failed_connection_restores_previous_credentials() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    cat > "$temp_dir/wpa_supplicant.conf" <<'EOF'
country=US
network={
    ssid=4578697374696e67
    psk="working-password"
}
EOF
    cp "$temp_dir/wpa_supplicant.conf" "$temp_dir/before.conf" || return 1
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    show_infobox() { :; }
    require_tools() { return 0; }
    detect_interface() { return 0; }
    prompt_country_code() { return 0; }
    list_wifi() { printf 'Existing\twpa\tStrong\t100\t4578697374696e67\n'; }
    capture_dialog() { printf '0\n'; }
    prompt_for_key() { printf 'wrong-password\n'; }
    command_exists() { return 1; }
    current_ssid() { printf 'Existing\n'; }
    current_ip() {
        [[ ! -e "$temp_dir/flushed" ]] && printf '192.0.2.70\n'
    }
    apply_wifi_settings() {
        : > "$temp_dir/flushed"
        return 1
    }
    reload_wpa_supplicant() { : > "$temp_dir/reloaded"; }
    wait_for_association() { printf '%s\n' "$1"; }
    preserve_ssh_client_route() { :; }
    start_dhcp_lease_request() { : > "$temp_dir/dhcp-restarted"; }
    wait_for_ipv4_lease() {
        [[ "$1" == "Existing" ]] || return 1
        : > "$temp_dir/lease-recovered"
        printf '192.0.2.71\n'
    }
    printMsgs() { :; }
    sync() { :; }

    if connect_wifi; then
        return 1
    fi
    cmp -s "$temp_dir/before.conf" "$WPA_CONF" || return 1
    [[ -e "$temp_dir/reloaded" ]] || return 1
    [[ -e "$temp_dir/dhcp-restarted" && -e "$temp_dir/lease-recovered" ]] || return 1
    [[ -z $(find "$temp_dir" -name 'wpa_supplicant.conf.rollback.*' -print -quit) ]]
}

test_exit_cleanup_restores_runtime_config() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    cat > "$temp_dir/wpa_supplicant.conf" <<'EOF'
country=US
network={
    ssid=4578697374696e67
    psk="working-password"
}
EOF
    cp "$temp_dir/wpa_supplicant.conf" "$temp_dir/before.conf" || return 1
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    sync() { :; }
    recover_previous_wifi_connection() {
        [[ "$1" == "Existing" ]] || return 1
        : > "$temp_dir/runtime-reloaded"
    }

    begin_wpa_rollback Existing || return 1
    printf 'country=CA\n' > "$WPA_CONF"
    cleanup

    cmp -s "$temp_dir/before.conf" "$WPA_CONF" || return 1
    [[ -e "$temp_dir/runtime-reloaded" ]] || return 1
    [[ "$WPA_ROLLBACK_ACTIVE" -eq 0 && -z "$WPA_ROLLBACK_FILE" && -z "$WPA_ROLLBACK_SSID" ]]
}

test_apply_flushes_old_lease_before_dhcp() {
    local temp_dir flush_line dhcp_line

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    printMsgs() { :; }
    show_infobox() { :; }
    warn_if_cifs_boot_hooks_exist() { :; }
    set_interface_state() { return 0; }
    reload_wpa_supplicant() { return 0; }
    select_target_network() { [[ "$1" == "Target" ]]; }
    wait_for_association() { printf '%s\n' "$1"; }
    preserve_ssh_client_route() { :; }
    ip() {
        printf 'ip %s\n' "$*" >> "$temp_dir/lifecycle"
        return 0
    }
    start_dhcp_lease_request() {
        printf 'dhcp\n' >> "$temp_dir/lifecycle"
        return 0
    }
    wait_for_ipv4_lease() {
        [[ "$1" == "Target" ]] || return 1
        printf '192.0.2.55\n'
    }
    connection_health_report() { printf 'healthy\n'; }

    apply_wifi_settings Target || return 1
    flush_line=$(grep -n 'addr flush dev wlan0 scope global' "$temp_dir/lifecycle" | cut -d: -f1)
    dhcp_line=$(grep -n '^dhcp$' "$temp_dir/lifecycle" | cut -d: -f1)
    [[ -n "$flush_line" && -n "$dhcp_line" && "$flush_line" -lt "$dhcp_line" ]]
}

test_failed_country_apply_preserves_config() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    printf 'country=US\n' > "$temp_dir/wpa_supplicant.conf"
    cp "$temp_dir/wpa_supplicant.conf" "$temp_dir/before.conf" || return 1
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    printMsgs() { :; }
    capture_dialog() { printf 'CA\n'; }
    apply_regulatory_country() { return 1; }
    sync() { :; }

    if prompt_country_code 1; then
        return 1
    fi
    cmp -s "$temp_dir/before.conf" "$WPA_CONF" || return 1
    ! is_valid_country_code ZZ
}

test_scan_prefers_secure_variant_for_duplicate_ssid() {
    local temp_dir result

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    set_interface_state() { return 0; }
    show_infobox() { :; }
    printMsgs() { :; }
    run_with_timeout() {
        cat <<'EOF'
          Cell 01 - Address: 00:00:00:00:00:01
                    Quality=70/70  Signal level=-30 dBm
                    Encryption key:off
                    ESSID:"SameName"
          Cell 02 - Address: 00:00:00:00:00:02
                    Quality=20/70  Signal level=-75 dBm
                    Encryption key:on
                    ESSID:"SameName"
                    IE: IEEE 802.11i/WPA2 Version 1
EOF
    }

    result=$(list_wifi) || return 1
    [[ $(printf '%s\n' "$result" | awk 'END { print NR + 0 }') -eq 1 ]] || return 1
    [[ "$result" == $'SameName\twpa\t'* ]]
}

test_iwlist_escaped_ssids_keep_canonical_identity() {
    local temp_dir result decoded

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    set_interface_state() { return 0; }
    show_infobox() { :; }
    printMsgs() { :; }
    run_with_timeout() {
        cat <<'EOF'
          Cell 01 - Address: 00:00:00:00:00:01
                    Quality=70/70  Signal level=-30 dBm
                    Encryption key:on
                    ESSID:"Caf\xC3\xA9"
                    IE: IEEE 802.11i/WPA2 Version 1
          Cell 02 - Address: 00:00:00:00:00:02
                    Quality=60/70  Signal level=-40 dBm
                    Encryption key:off
                    ESSID:"Literal\x41"
          Cell 03 - Address: 00:00:00:00:00:03
                    Quality=50/70  Signal level=-50 dBm
                    Encryption key:off
                    ESSID:"Path\x5Cx41Z"
          Cell 04 - Address: 00:00:00:00:00:04
                    Quality=40/70  Signal level=-60 dBm
                    Encryption key:off
                    ESSID:"<hidden>"
EOF
    }

    result=$(list_wifi) || return 1
    printf '%s\n' "$result" | grep -Fqx $'Caf\\xC3\\xA9\twpa\tStrong\t100\t436166c3a9' || return 1
    printf '%s\n' "$result" | grep -Fqx $'Literal\\x41\topen\tStrong\t85\t4c69746572616c5c783431' || return 1
    printf '%s\n' "$result" | grep -Fqx $'Path\\x5Cx41Z\topen\tGood\t71\t506174685c7834315a' || return 1
    printf '%s\n' "$result" | grep -Fqx $'<hidden>\topen\tGood\t57\t3c68696464656e3e' || return 1
    decoded=$(wpa_hex_to_string 436166c3a9) || return 1
    [[ $(string_to_wpa_hex "$decoded") == "436166c3a9" ]]
}

test_non_psk_auth_suites_are_not_configured() {
    local temp_dir result last_message=""

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    set_interface_state() { return 0; }
    show_infobox() { :; }
    printMsgs() { last_message="$*"; }
    run_with_timeout() {
        cat <<'EOF'
          Cell 01 - Address: 00:00:00:00:00:01
                    Quality=70/70  Signal level=-30 dBm
                    Encryption key:on
                    ESSID:"Enterprise"
                    IE: IEEE 802.11i/WPA2 Version 1
                        Authentication Suites (1) : 802.1x
          Cell 02 - Address: 00:00:00:00:00:02
                    Quality=60/70  Signal level=-40 dBm
                    Encryption key:on
                    ESSID:"SAEOnly"
                    IE: IEEE 802.11i/WPA2 Version 1
                        Authentication Suites (1) : SAE
          Cell 03 - Address: 00:00:00:00:00:03
                    Quality=50/70  Signal level=-50 dBm
                    Encryption key:on
                    ESSID:"Transition"
                    IE: IEEE 802.11i/WPA2 Version 1
                        Authentication Suites (2) : PSK SAE
          Cell 04 - Address: 00:00:00:00:00:04
                    Quality=40/70  Signal level=-60 dBm
                    Encryption key:on
                    ESSID:"OWEOnly"
                    IE: IEEE 802.11i/WPA2 Version 1
                        Authentication Suites (1) : OWE
          Cell 05 - Address: 00:00:00:00:00:05
                    Quality=70/70  Signal level=-30 dBm
                    Encryption key:off
                    ESSID:"Enterprise"
EOF
    }

    result=$(list_wifi) || return 1
    printf '%s\n' "$result" | grep -Fq $'Enterprise\tunsupported\t' || return 1
    printf '%s\n' "$result" | grep -Fq $'SAEOnly\tunsupported\t' || return 1
    printf '%s\n' "$result" | grep -Fq $'OWEOnly\tunsupported\t' || return 1
    printf '%s\n' "$result" | grep -Fq $'Transition\twpa\t' || return 1
    [[ $(printf '%s\n' "$result" | grep -Fc $'Enterprise\t') -eq 1 ]] || return 1

    require_tools() { return 0; }
    detect_interface() { return 0; }
    prompt_country_code() { return 0; }
    list_wifi() { printf 'Enterprise\tunsupported\tStrong\t100\t456e7465727072697365\n'; }
    capture_dialog() { printf '0\n'; }
    append_network_config() { : > "$temp_dir/appended"; }

    if connect_wifi; then
        return 1
    fi
    [[ ! -e "$temp_dir/appended" ]] || return 1
    [[ "$last_message" == *"not supported"* ]]
}

test_disconnect_failure_is_reported() {
    local temp_dir last_message=""

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    show_infobox() { :; }
    require_tools() { return 0; }
    detect_interface() { return 0; }
    command_exists() { [[ "$1" == "wpa_cli" || "$1" == "iw" ]]; }
    current_ssid() { printf 'StillConnected\n'; }
    current_ip() { printf '192.0.2.60\n'; }
    sleep() { :; }
    run_with_timeout() {
        shift
        if [[ "$1" == "ip" ]]; then
            return 0
        fi
        return 1
    }
    printMsgs() {
        last_message="$*"
    }

    if disconnect_wifi; then
        return 1
    fi
    [[ "$last_message" == *"Unable to disconnect"* ]]
}

test_diagnostics_succeeds_without_dmesg_matches() {
    local temp_dir

    temp_dir=$(mktemp -d) || return 1
    trap "rm -rf '$temp_dir'" EXIT
    : > "$temp_dir/wpa_supplicant.conf"
    source_wifi "$temp_dir/wpa_supplicant.conf" || return 1
    command_exists() { [[ "$1" == "dmesg" ]]; }
    find_wireless_interface_once() { return 1; }
    dmesg() { printf 'unrelated kernel line\n'; }
    ip() { return 1; }

    diagnose_wifi > "$temp_dir/diagnostics.txt" || return 1
    grep -q -- '--- Relevant dmesg ---' "$temp_dir/diagnostics.txt"
}

test_no_global_or_process_wide_supplicant_kill() {
    ! grep -Eq 'pkill[[:space:]].*wpa_supplicant|killall[[:space:]].*wpa_supplicant|wpa_cli.*terminate' "$WIFI_SCRIPT"
}

run_test "syntax" test_syntax
run_test "library mode preserves EXIT trap" test_library_mode_preserves_exit_trap
run_test "console output keeps untrusted escapes literal" test_console_output_does_not_expand_untrusted_escapes
run_test "connection summary includes radio metrics" test_connection_summary_includes_radio_metrics
run_test "connection summary tolerates missing optional tools" test_connection_summary_degrades_without_optional_metric_tools
run_test "DNS lookup requires an answer address" test_dns_lookup_requires_an_answer_address
run_test "failed DNS resolver is not reported as missing" test_failed_dns_resolver_is_not_reported_as_missing
run_test "main menu prioritizes connection actions" test_main_menu_prioritizes_connection_actions
run_test "country update preserves globals" test_country_update_is_atomic_and_preserves_globals
run_test "repair preserves valid content" test_repair_preserves_valid_content
run_test "validator rejects malformed SSIDs" test_validator_rejects_empty_and_unterminated_ssids
run_test "escaped SSID removal is exact" test_escaped_ssid_removal_is_exact
run_test "failed WPA generation preserves config" test_failed_wpa_generation_preserves_config
run_test "WPA key validation and raw PSK" test_wpa_key_validation_and_raw_psk
run_test "failed atomic move preserves config" test_failed_atomic_move_preserves_config
run_test "WEP key lengths match supplicant" test_wep_key_lengths_match_supplicant
run_test "reconnect dependencies are headless" test_reconnect_has_headless_dependencies
run_test "saved country applies without prompt" test_saved_country_is_applied_without_prompt
run_test "supplicant recovery and selection are scoped" test_supplicant_recovery_is_scoped_and_selection_checks_ok
run_test "DHCP selection and status propagation" test_dhcp_prefers_dhcpcd_and_propagates_failure
run_test "stale IP is rejected" test_stale_ip_is_rejected_after_association_changes
run_test "hidden-only scan can connect" test_hidden_network_remains_available_after_empty_scan
run_test "failed connection restores credentials" test_failed_connection_restores_previous_credentials
run_test "EXIT cleanup restores runtime config" test_exit_cleanup_restores_runtime_config
run_test "old lease flush precedes DHCP" test_apply_flushes_old_lease_before_dhcp
run_test "failed country apply preserves config" test_failed_country_apply_preserves_config
run_test "duplicate SSID prefers secure variant" test_scan_prefers_secure_variant_for_duplicate_ssid
run_test "iwlist escapes keep canonical SSID identity" test_iwlist_escaped_ssids_keep_canonical_identity
run_test "non-PSK auth suites are not configured" test_non_psk_auth_suites_are_not_configured
run_test "disconnect failure is reported" test_disconnect_failure_is_reported
run_test "diagnostics tolerate no dmesg matches" test_diagnostics_succeeds_without_dmesg_matches
run_test "no global supplicant kill" test_no_global_or_process_wide_supplicant_kill

printf '\nResults: %d passed, %d failed\n' "$passed" "$failed"
[[ "$failed" -eq 0 ]]
