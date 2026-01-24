{ config, lib, pkgs, ... }:

{
  # Configure Pi-hole adlists via systemd service
  # This approach waits for the database to be fully initialized before adding lists
  # The gravity and antigravity tables need to exist before we can add adlists
  systemd.services.pihole-adlists-setup = {
    description = "Configure Pi-hole adlists/blocklists";
    wantedBy = [ "multi-user.target" ];
    after = [ "pihole-ftl.service" ];
    wants = [ "pihole-ftl.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = "PATH=/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin";
      ExecStart = "${pkgs.writeShellScriptBin "pihole-adlists-setup" ''
        # Pi-hole gravity database location (confirmed from earlier debugging)
        GRAVITY_DB="/var/lib/pihole/gravity.db"
        
        # Wait for pihole-ftl to initialize database and create gravity/antigravity tables
        # The errors show these tables need to exist before we can add adlists
        echo "Waiting for Pi-hole database to initialize..."
        for i in {1..30}; do
          if ${pkgs.sqlite}/bin/sqlite3 "$GRAVITY_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='gravity';" 2>/dev/null | grep -q gravity; then
            echo "Database tables ready!"
            break
          fi
          sleep 2
        done
        
        # Function to add adlist if it doesn't exist
        add_adlist() {
          local url="$1"
          local comment="$2"
          local enabled="$3"
          
          # Check if URL already exists
          local exists=$(${pkgs.sqlite}/bin/sqlite3 "$GRAVITY_DB" \
            "SELECT COUNT(*) FROM adlist WHERE address = '$url' LIMIT 1;" 2>/dev/null || echo "0")
          
          if [ "$exists" = "0" ]; then
            ${pkgs.sqlite}/bin/sqlite3 "$GRAVITY_DB" \
              "INSERT OR IGNORE INTO adlist (address, comment, enabled) VALUES ('$url', '$comment', $enabled);" 2>/dev/null
            if [ $? -eq 0 ]; then
              echo "Added: $comment"
            else
              echo "Failed to add: $comment (database may not be ready yet)"
            fi
          else
            echo "Already exists: $comment"
          fi
        }
        
        # ============================================================================
        # PHASE 1: IMMEDIATE ACTIONS - Security & Malware Protection
        # These lists focus on security without breaking social media functionality
        # ============================================================================
        
        # Steven Black's Unified Hosts (Malware + Ads)
        add_adlist \
          "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" \
          "Steven Black - Unified Hosts (Malware + Ads)" \
          1
        
        # Phishing Army - Extended Blocklist
        add_adlist \
          "https://phishing.army/download/phishing_army_blocklist_extended.txt" \
          "Phishing Army - Extended Protection" \
          1
        
        # Alternative: MalwareDomains (if you want additional malware protection)
        # add_adlist \
        #   "https://mirror1.malwaredomains.com/files/domains.txt" \
        #   "MalwareDomains - Malware Domain List" \
        #   1
        
        # ============================================================================
        # PHASE 2: NEXT STEPS (COMMENTED OUT) - Test Phase 1 for 1-2 weeks first!
        # Uncomment these ONLY after confirming Meta products work properly
        # ============================================================================
        
        # AdAway Default Blocklist
        # add_adlist \
        #   "https://adaway.org/hosts.txt" \
        #   "AdAway - Default Blocklist" \
        #   1
        
        # Yoyo.org Ad Servers
        # add_adlist \
        #   "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext" \
        #   "Peter Lowe - Ad Servers" \
        #   1
        
        # Disconnect.me Simple Tracking
        # add_adlist \
        #   "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt" \
        #   "Disconnect.me - Simple Tracking" \
        #   1
        
        # Disconnect.me Simple Ad
        # add_adlist \
        #   "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt" \
        #   "Disconnect.me - Simple Ad" \
        #   1
        
        # Update gravity database to apply changes
        echo "Updating gravity database..."
        if command -v pihole &> /dev/null; then
          pihole -g
        elif [ -x /usr/local/bin/pihole ]; then
          /usr/local/bin/pihole -g
        else
          echo "Warning: pihole command not found. Lists added but gravity update needed."
        fi
      ''}/bin/pihole-adlists-setup";
    };
  };
}

