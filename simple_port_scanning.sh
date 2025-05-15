#!/bin/bash

# Fungsi untuk mendapatkan deskripsi port dari /etc/services
get_port_info() {
  local port=$1
  local service_info=$(grep -w "$port/tcp" /etc/services | awk '{print $1, $2}')
  if [ -z "$service_info" ]; then
    echo "Unknown"
  else
    echo "$service_info"
  fi
}

# Fungsi untuk memindai port + deteksi versi (jika diperlukan)
scan_port() {
  local ip=$1
  local port=$2
  local scan_version=$3

  if nc -zv -w 1 "$ip" "$port" &>/dev/null; then
    local port_info=$(get_port_info "$port")
    echo -n "Port $port ($port_info): OPEN"

    # Jika diminta, lakukan deteksi versi (menggunakan nmap)
    if [ "$scan_version" = true ]; then
      local version_info=$(nmap -p "$port" -sV --version-intensity 0 "$ip" 2>/dev/null | grep -E "^$port/tcp")
      if [ -n "$version_info" ]; then
        echo -n " | Service: $version_info"
      fi
    fi

    echo ""  # New line
  else
    echo "Port $port: CLOSED"
  fi
}

# Fungsi utama
main() {
  echo "=== Advanced Network Port Scanner ==="
  
  read -p "Enter target IP: " target_ip
  read -p "Enter port range (e.g., 1-100): " port_range
  read -p "Enable version detection? (y/n): " enable_version

  scan_version=false
  if [[ "$enable_version" =~ ^[Yy] ]]; then
    scan_version=true
    echo "[!] Version detection enabled (requires nmap)."
  fi

  start_port=$(echo "$port_range" | cut -d'-' -f1)
  end_port=$(echo "$port_range" | cut -d'-' -f2)

  echo "Scanning $target_ip (ports $start_port-$end_port)..."
  
  for (( port=start_port; port<=end_port; port++ )); do
    scan_port "$target_ip" "$port" "$scan_version"
  done

  echo "Scan completed!"
}

# Jalankan fungsi utama
main