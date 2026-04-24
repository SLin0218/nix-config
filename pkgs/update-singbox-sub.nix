{ pkgs }:

pkgs.writeShellScriptBin "update-singbox-sub" ''
  export PATH="${pkgs.coreutils}/bin:${pkgs.curl}/bin:${pkgs.jq}/bin:$PATH"

  if [[ "$(uname)" == "Darwin" ]]; then
    OUTBOUNDS_FILE="/etc/sing-box/outbounds.json"
  else
    OUTBOUNDS_FILE="/run/sing-box/outbounds.json"
  fi

  # 这里使用的 secretPath 是从 Nix 传入的
  export $(grep -v '^#' "/run/agenix/update-subscription" | xargs)

  echo "Updating subscription using $SERVICE and $ID..."
  SUBSCRIPTION_URL="https://jmssub.net/members/getsub.php?service=$SERVICE&id=$ID"
  SUBS_RESP=$(curl -s "''${SUBSCRIPTION_URL}")

  if [ -z "$SUBS_RESP" ]; then
    echo "Warning: Failed to fetch subscription. Generating fallback..."
    mkdir -p "$(dirname "$OUTBOUNDS_FILE")"
    echo '{"outbounds":[{"type":"selector","tag":"proxy","outbounds":["auto","direct"]},{"type":"urltest","tag":"auto","outbounds":["direct"]},{"type":"direct","tag":"direct"}]}' > "$OUTBOUNDS_FILE"
    exit 0
  fi

  BASE_OUTBOUNDS='[{"type":"selector","tag":"proxy","outbounds":["auto"]},{"type":"urltest","tag":"auto","outbounds":[]},{"type":"direct","tag":"direct"}]'
  NODES_JSON=""

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    proto="''${line%%://*}"
    content="''${line#*://}"
    content="''${content%%#*}"
    len=$((''${#content} % 4))
    [ $len -eq 2 ] && content="''${content}=="
    [ $len -eq 3 ] && content="''${content}="
    decoded=$(echo "$content" | base64 -d 2>/dev/null)
    [ -z "$decoded" ] && continue

    if [ "$proto" = "ss" ]; then
      tag_tmp="''${line#*@}"
      tag_name="''${tag_tmp%%.*}"
      node=$(jq -nc --arg d "$decoded" --arg tn "$tag_name" '
              ($d | split("@")) as $parts |
              ($parts[0] | split(":")) as $cred |
              ($parts[1] | split(":")) as $addr |
              if ($addr | length) < 2 then empty
              else { "tag": $tn, "type": "shadowsocks", "server": $addr[0], "server_port": ($addr[1] | tonumber), "password": $cred[1], "method": $cred[0] } end')
    elif [ "$proto" = "vmess" ]; then
      node=$(echo "$decoded" | jq -c '
              if . == null then empty
              else { "tag": (.ps | capture("@(?<t>[0-9a-zA-Z]+)\\.").t // .ps // "unnamed"), "type": "vmess", "server": .add, "server_port": (.port | tonumber), "uuid": .id, "alter_id": (.aid | tonumber), "security": "auto" } end')
    fi
    if [ -n "$node" ]; then
      NODES_JSON="''${NODES_JSON}''${node}"$'\n'
    fi
  done <<EOF
$(echo "$SUBS_RESP" | base64 -d 2>/dev/null || echo "")
EOF

  mkdir -p "$(dirname "$OUTBOUNDS_FILE")"
  if [ -n "$NODES_JSON" ]; then
    echo "$NODES_JSON" | jq -s --argjson base "$BASE_OUTBOUNDS" '
          . as $new_nodes |
          ($new_nodes | map(.tag)) as $tags |
          ($base | .[0].outbounds += $tags | .[1].outbounds += $tags) + $new_nodes |
          {outbounds: .}
      ' > "$OUTBOUNDS_FILE"
  fi
''
