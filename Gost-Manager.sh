#!/bin/bash

# ==============================================================================
# Project: Gost-Manager
# Description: Advanced encrypted tunnel management with anti-DPI capabilities
# Version: 1.0.0
# GitHub: https://github.com/SpeedwiT/Speed-Tunneling
# ==============================================================================

# ==============================================================================
# 1. CONFIGURATION DEFAULTS
# ==============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly ORANGE='\033[0;33m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

readonly SCRIPT_VERSION="1.0.0"
readonly MANAGER_NAME="gost-manager"
readonly MANAGER_PATH="/usr/local/bin/$MANAGER_NAME"

readonly CONFIG_DIR="/etc/gost"
readonly SERVICE_DIR="/etc/systemd/system"
readonly BIN_DIR="/usr/local/bin"
readonly LOG_DIR="/var/log/gost"
readonly TLS_DIR="${CONFIG_DIR}/tls"
readonly BACKUP_DIR="/root/gost-backups"
readonly WATCHDOG_PATH="${BIN_DIR}/gost-watchdog"
readonly BIN_PATH="${BIN_DIR}/gost"

# IP detection services
readonly IP_SERVICES=(
    "ifconfig.me"
    "icanhazip.com"
    "api.ipify.org"
    "checkip.amazonaws.com"
    "ipinfo.io/ip"
)

# ==============================================================================
# 2. UTILITY FUNCTIONS
# ==============================================================================

print_step() { echo -e "${BLUE}[•]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_info() { echo -e "${CYAN}[i]${NC} $1"; }

# Special input function that keeps cursor on same line
prompt_input() {
    echo -ne "${YELLOW}[•]${NC} $1 "
}

pause() {
    echo ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" </dev/tty
}

_BANNER_PLAYED=0

show_banner() {
    clear
    export LC_ALL=C.UTF-8 2>/dev/null || export LC_ALL=en_US.UTF-8 2>/dev/null

    local width=64
    local border
    border=$(printf '═%.0s' $(seq 1 "$width"))

    local art=(
        "███████╗██████╗ ███████╗███████╗██████╗ ██╗████████╗"
        "██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗██║╚══██╔══╝"
        "███████╗██████╔╝█████╗  █████╗  ██║  ██║██║   ██║   "
        "╚════██║██╔═══╝ ██╔══╝  ██╔══╝  ██║  ██║██║   ██║   "
        "███████║██║     ███████╗███████╗██████╔╝██║   ██║   "
        "╚══════╝╚═╝     ╚══════╝╚══════╝╚═════╝ ╚═╝   ╚═╝   "
    )
    local art_width=${#art[0]}
    local art_pad_left=$(( (width - art_width) / 2 ))
    local art_pad_right=$(( width - art_width - art_pad_left ))
    local rows=${#art[@]}

    # پالت موج نور: از بنفش تیره تا صورتی/سفید روشن و برگشت
    local wave=(53 89 90 126 127 163 164 200 201 213 219 255 219 213 201 200 164 163 127 126 90 89)
    local band=${#wave[@]}
    local base=53

    print_line() {
        local text="$1"
        local len=${#text}
        local pad_left=$(( (width - len) / 2 ))
        local pad_right=$(( width - len - pad_left ))
        printf '║%*s%s%*s║\n' "$pad_left" '' "$text" "$pad_right" ''
    }
    print_empty() { printf '║%*s║\n' "$width" ''; }

    render_frame() {
        local pos=$1
        for row in "${art[@]}"; do
            local line=""
            local i=0
            local n=${#row}
            while (( i < n )); do
                local ch="${row:$i:1}"
                local diff=$(( i - pos ))
                if (( diff >= 0 && diff < band )); then
                    line+="\033[38;5;${wave[$diff]}m${ch}"
                else
                    line+="\033[38;5;${base}m${ch}"
                fi
                (( i++ ))
            done
            printf '║%*s%b\033[0m%*s║\n' "$art_pad_left" '' "$line" "$art_pad_right" ''
        done
    }

    printf '\033[35m'
    printf '╔%s╗\n' "$border"
    print_empty
    printf '\033[0m'

    # انیمیشن فقط یه بار توی کل اجرای اسکریپت پلی میشه، نه هر بار که منو رفرش میشه
    if [[ "$_BANNER_PLAYED" -eq 0 ]]; then
        local delay=0.018
        local cycles=2

        for ((c=0; c<cycles; c++)); do
            for ((pos=-band; pos<=art_width; pos++)); do
                render_frame "$pos"
                sleep "$delay"
                printf '\033[%dA' "$rows"
            done
            for ((pos=art_width; pos>=-band; pos--)); do
                render_frame "$pos"
                sleep "$delay"
                printf '\033[%dA' "$rows"
            done
        done
        _BANNER_PLAYED=1
    fi

    printf '\033[35m'
    for row in "${art[@]}"; do
        printf '║%*s%s%*s║\n' "$art_pad_left" '' "$row" "$art_pad_right" ''
    done

    print_empty
    print_line "Encrypted Tunnel Manager - Anti-DPI"
    print_line "Version ${SCRIPT_VERSION}"
    print_empty
    print_line "https://t.me/Speedw_IT"
    print_line "https://t.me/SpeedwIT"
    print_line "https://github.com/SpeedwiT"
    print_empty
    printf '╚%s╝\n' "$border"
    printf '\033[0m'
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "linux"
    fi
}

detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) 
            print_warning "Unknown architecture: $arch, assuming amd64"
            echo "amd64" 
            ;;
    esac
}

get_public_ip() {
    for service in "${IP_SERVICES[@]}"; do
        local ip=$(curl -4 -s --max-time 2 "$service" 2>/dev/null)
        if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    echo "Unknown"
}

validate_ip() {
    local ip=$1
    [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

validate_port() {
    local port=$1
    [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
}

clean_port_list() {
    local ports="$1"
    ports=$(echo "$ports" | tr -d ' ')
    local cleaned=""
    
    IFS=',' read -ra port_array <<< "$ports"
    for port in "${port_array[@]}"; do
        if validate_port "$port"; then
            cleaned="${cleaned:+$cleaned,}$port"
        else
            print_warning "Invalid port '$port' ignored" >&2
        fi
    done
    echo "$cleaned"
}

check_crontab() {
    if ! command -v crontab &>/dev/null; then
        print_warning "crontab not found, watchdog disabled"
        return 1
    fi
    return 0
}

check_module() {
    local module=$1
    if ! lsmod | grep -q "^$module"; then
        print_warning "Kernel module $module not loaded"
        prompt_input "Load now? (y/N):"
        read -p "" choice </dev/tty
        echo ""
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            modprobe "$module" 2>/dev/null
            if [ $? -eq 0 ]; then
                print_success "Module $module loaded"
            else
                print_error "Failed to load $module"
                return 1
            fi
        else
            return 1
        fi
    fi
    return 0
}

# ==============================================================================
# 3. SYSTEM SETUP
# ==============================================================================

setup_environment() {
    print_step "Initializing environment..."
    
    local packages=("wget" "curl" "cron" "openssl" "nano" "jq")
    local missing=()
    
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        apt-get update -qq >/dev/null 2>&1
        apt-get install -y "${missing[@]}" -qq >/dev/null 2>&1
    fi
    
    mkdir -p "$LOG_DIR" "$TLS_DIR" "$BACKUP_DIR"
    print_success "Environment ready"
}

configure_firewall() {
    local port=$1
    if ! validate_port "$port"; then return 1; fi
    
    if command -v ufw &>/dev/null; then
        ufw allow "$port"/tcp &>/dev/null
        ufw allow "$port"/udp &>/dev/null
        print_success "Firewall rule added for port $port (UFW)"
    elif command -v iptables &>/dev/null; then
        iptables -I INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null
        iptables -I INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null
        print_success "Firewall rule added for port $port (iptables)"
    fi
}

configure_firewall_protocol() {
    local port=$1
    local protocol=$2
    if ! validate_port "$port"; then return 1; fi
    
    if command -v ufw &>/dev/null; then
        case $protocol in
            tcp) ufw allow "$port"/tcp &>/dev/null ;;
            udp) ufw allow "$port"/udp &>/dev/null ;;
            both) 
                ufw allow "$port"/tcp &>/dev/null
                ufw allow "$port"/udp &>/dev/null
                ;;
        esac
        print_success "Firewall rule added for port $port ($protocol) - UFW"
    elif command -v iptables &>/dev/null; then
        case $protocol in
            tcp) iptables -I INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null ;;
            udp) iptables -I INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null ;;
            both)
                iptables -I INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null
                iptables -I INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null
                ;;
        esac
        print_success "Firewall rule added for port $port ($protocol) - iptables"
    fi
}

# ==============================================================================
# 4. CORE INSTALLATION
# ==============================================================================

deploy_gost_binary() {
    if [[ -f "$BIN_PATH" ]]; then
        print_success "GOST binary already installed"
        return 0
    fi

    local arch=$(detect_arch)
    local version="2.12.0"
    local base_url="https://github.com/ginuerzh/gost/releases/download/v${version}"

    local filename=""
    if [[ "$arch" == "amd64" ]]; then
        filename="gost_${version}_linux_amd64.tar.gz"
    elif [[ "$arch" == "arm64" ]]; then
        filename="gost_${version}_linux_arm64.tar.gz"
    else
        print_error "Unsupported architecture: $arch"
        exit 1
    fi

    print_step "Downloading GOST v${version} for ${arch}..."

    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if wget -q --timeout=10 --tries=2 "${base_url}/${filename}" -O /tmp/gost.tar.gz; then
            if [[ -s "/tmp/gost.tar.gz" ]]; then
                tar -xzf /tmp/gost.tar.gz -C /tmp
                if [[ -f "/tmp/gost" ]]; then
                    mv /tmp/gost "$BIN_PATH"
                    chmod +x "$BIN_PATH"

                    if [[ -x "$BIN_PATH" ]]; then
                        print_success "GOST v${version} installed successfully"
                        rm -f /tmp/gost.tar.gz /tmp/README.md
                        return 0
                    fi
                else
                    print_warning "gost binary not found in tar.gz"
                fi
            fi
        fi
        print_warning "Attempt $attempt failed, retrying..."
        ((attempt++))
        sleep 2
    done

    print_error "Failed to download or extract GOST after $max_attempts attempts"
    exit 1
}

# ==============================================================================
# 5. SECURITY COMPONENTS
# ==============================================================================

generate_tunnel_key() {
    openssl rand -hex 12
}

function generate_tls_certificate() {
    mkdir -p "$TLS_DIR"

    if [[ ! -f "$TLS_DIR/server.crt" ]]; then
        print_step "Generating stealth TLS certificate..."
        openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
            -subj "/C=US/ST=CA/L=Los Angeles/O=Speedtest Inc/CN=www.speedtest.net" \
            -keyout "$TLS_DIR/server.key" \
            -out "$TLS_DIR/server.crt" 2>/dev/null
    fi

    if [[ -f "$TLS_DIR/server.crt" && -f "$TLS_DIR/server.key" ]]; then
        print_success "Stealth TLS certificate created (with SAN) for $server_ip"
    else
        print_error "Failed to generate TLS certificate"
        return 1
    fi
}

# ==============================================================================
# 6. TUNNEL PROFILES (FIXED: sends menu to stderr, returns only data)
# ==============================================================================
select_tunnel_profile() {
    export LC_ALL=C.UTF-8 2>/dev/null || export LC_ALL=en_US.UTF-8 2>/dev/null

    # چاپ یک ردیف پروفایل با تراز خودکار ستون ستاره‌ها، مستقل از طول متن
    print_profile() {
        local num="$1" name="$2" desc="$3" stars="$4"
        local label_width=58
        local bracket
        bracket=$(printf '[%s]' "$num")
        local plain="${bracket} ${name} (${desc})"
        local len=${#plain}
        local pad=$(( label_width - len ))
        (( pad < 1 )) && pad=1
        local starline=""
        local s
        for ((s=0; s<stars; s++)); do
            starline+="★"
            (( s < stars-1 )) && starline+=" "
        done
        printf "${WHITE}%s${NC} %s (%s)%*s${YELLOW}%s${NC}\n" \
            "$bracket" "$name" "$desc" "$pad" '' "$starline" >&2
    }

    echo "" >&2
    print_step "Select tunnel profile" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

    echo -e "${CYAN}► KCP FAMILY (UDP - Anti Packet Loss):${NC}" >&2
    print_profile "1"  "KCP-Normal"      "mode=normal - Balanced"        4
    print_profile "2"  "KCP-Fast"        "mode=fast - High speed"        4
    print_profile "3"  "KCP-Fast2"       "mode=fast2 - Very high speed"  4
    print_profile "4"  "KCP-Fast3"       "mode=fast3 - Maximum speed"    4
    print_profile "5"  "KCP-Manual"      "Advanced config"               5
    print_profile "6"  "KCP+obfs4-Fast3" "KCP fast3 + obfs4 stealth"     5

    echo -e "\n${GREEN}► TLS/SSL FAMILY (TCP - Enterprise Security):${NC}" >&2
    print_profile "7"  "TLS-Standard"    "Raw TLS encryption"            3
    print_profile "8"  "MTLS-Multiplex"  "TLS + multiplexing"            3

    echo -e "\n${YELLOW}► WEBSOCKET FAMILY (TCP - Web Compatible):${NC}" >&2
    print_profile "9"  "WS-Simple"       "WebSocket - plain"             5
    print_profile "10" "MWS-Multiplex"   "WebSocket + multiplex"         5
    print_profile "11" "WSS-Secure"      "WebSocket Secure"              6
    print_profile "12" "MWSS-Multiplex"  "WSS + multiplex"               6
    print_profile "13" "MW-Bind"         "Multiplex WS + bind mode"      4

    echo -e "\n${BLUE}► gRPC FAMILY (Modern RPC - High Performance):${NC}" >&2
    print_profile "14" "gRPC-Gun"        "Plain gRPC"                    4
    print_profile "15" "gRPC+TLS"        "gRPC with TLS"                 5
    print_profile "16" "gRPC+Keepalive"  "gRPC with keepalive"           4

    echo -e "\n${BLUE}► MODERN UDP FAMILY (UDP - Low Latency):${NC}" >&2
    print_profile "17" "QUIC-Standard"   "HTTP/3-like transport"         5

    echo -e "\n${MAGENTA}► HTTP2 FAMILY (Modern Protocols):${NC}" >&2
    print_profile "18" "HTTP2-Standard"  "HTTP/2 with TLS"               6
    print_profile "19" "H2C-Cleartext"   "HTTP/2 without TLS"            4

    echo -e "\n${ORANGE}► SSH FAMILY (Secure Shell):${NC}" >&2
    print_profile "20" "SSH-Tunnel"      "SSH protocol forwarding"       3

    echo -e "\n${PURPLE}► OBFUSCATION FAMILY (Maximum Stealth):${NC}" >&2
    print_profile "21" "obfs4"           "Tor bridges - strongest"       3

    echo -e "\n${CYAN}► SHADOWSOCKS FAMILY (Standard Encryption):${NC}" >&2
    print_profile "22" "SS-TCP"          "Shadowsocks TCP"               3
    print_profile "23" "SSU-UDP"         "Shadowsocks UDP relay"         3
    print_profile "24" "SS+TLS"          "Shadowsocks over TLS"          3
    print_profile "25" "SS+WS"           "Shadowsocks over WebSocket"    3

    echo -e "\n${GREEN}► COMBINED PROFILES (Ready-to-use recipes):${NC}" >&2
    print_profile "26" "Ultimate-Stealth" "obfs4 + TLS + relay"          3
    print_profile "27" "Web-Tunnel"       "HTTP + MWSS + Multiplex"      3
    print_profile "28" "Gaming-Optimized" "SOCKS5 + KCP"                 3
    print_profile "29" "Forward-SSH"      "Forward + SSH"                3
    print_profile "30" "QUIC + SOCKS5"    "QUIC first + SOCKS5"          3

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    local choice=""
    while true; do
        prompt_input "Select profile [1-30] (default: 12 - MWSS-Multiplex):" >&2
        read -p "" choice </dev/tty
        echo "" >&2
        
        choice=${choice:-12}

        case $choice in
            1) 
                echo "relay+kcp|mode=normal&crypt=aes-128-gcm&mtu=1350&sndwnd=2048&rcvwnd=2048&keepalive=true"
                return 0
                ;;
            2) 
                echo "relay+kcp|mode=fast&crypt=aes-128-gcm&mtu=1350&sndwnd=2048&rcvwnd=2048&keepalive=true"
                return 0
                ;;
            3) 
                echo "relay+kcp|mode=fast2&crypt=aes-128-gcm&mtu=1350&sndwnd=2048&rcvwnd=2048&keepalive=true"
                return 0
                ;;
            4) 
                echo "relay+kcp|mode=fast3&crypt=aes-128-gcm&mtu=1350&sndwnd=2048&rcvwnd=2048&keepalive=true"
                return 0
                ;;
            5) 
                echo "relay+kcp|mode=manual&resend=0&nc=1&dshard=10&pshard=3&mtu=1350&sndwnd=1024&rcvwnd=1024&keepalive=true&crypt=aes-128-gcm"
                return 0
                ;;
            6)
                echo "relay+kcp+obfs4|mode=fast3&crypt=chacha20&mtu=1350&sndwnd=2048&rcvwnd=2048&iat-mode=0"
                return 0
                ;;
            7) 
                echo "relay+tls|keepalive=true"
                return 0
                ;;
            8) 
                echo "relay+mtls|keepalive=true"
                return 0
                ;;
            9) 
                echo "relay+ws|keepalive=true"
                return 0
                ;;
            10) 
                echo "relay+mws|keepalive=true&ping=30"
                return 0
                ;;
            11) 
                echo "relay+wss|keepalive=true"
                return 0
                ;;
            12) 
                echo "relay+mwss|keepalive=true&ping=30"
                return 0
                ;;
            13)
                echo "relay+mw|keepalive=true&bind=true"
                return 0
                ;;
            14)
                echo "relay+grpc|keepalive=true&ping=30"
                return 0
                ;;
            15)
                echo "relay+grpc+tls|keepalive=true"
                return 0
                ;;
            16)
                echo "relay+grpc|keepalive=true"
                return 0
                ;;
            17) 
                echo "relay+quic|keepalive=true&timeout=30"
                return 0
                ;;
            18) 
                echo "relay+h2|keepalive=true"
                return 0
                ;;
            19) 
                echo "relay+h2c|keepalive=true"
                return 0
                ;;
            20) 
                echo "forward+ssh|ping=60"
                return 0
                ;;
            21) 
                echo "relay+obfs4|iat-mode=0"
                return 0
                ;;
            22) 
                echo "ss|aes-256-gcm"
                return 0
                ;;
            23)
                echo "ssu|aes-256-gcm"
                return 0
                ;;
            24)
                echo "ss+tls|aes-256-gcm"
                return 0
                ;;
            25)
                echo "ss+ws|aes-256-gcm"
                
