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
      # Allow retries on first boot when database may not be ready
      Restart = "on-failure";
      RestartSec = "10s";
      RestartMaxDelaySec = "60s";
      Environment = "PATH=/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin";
      ExecStart = "${pkgs.writeShellScriptBin "pihole-adlists-setup" ''
        set -euo pipefail
        
        # Pi-hole gravity database location
        GRAVITY_DB="/var/lib/pihole/gravity.db"
        
        # Wait for pihole-ftl to be running
        echo "Waiting for Pi-hole FTL to start..."
        for i in {1..30}; do
          if systemctl is-active --quiet pihole-ftl.service; then
            echo "Pi-hole FTL is running!"
            break
          fi
          echo "Waiting for pihole-ftl service... ($i/30)"
          sleep 2
        done
        
        if ! systemctl is-active --quiet pihole-ftl.service; then
          echo "ERROR: pihole-ftl not running. Cannot proceed."
          exit 1
        fi
        
        # Find pihole command
        PIHOLE_CMD=""
        if command -v pihole &> /dev/null; then
          PIHOLE_CMD="pihole"
        elif [ -x /usr/local/bin/pihole ]; then
          PIHOLE_CMD="/usr/local/bin/pihole"
        fi
        
        if [ -z "$PIHOLE_CMD" ]; then
          echo "ERROR: pihole command not found"
          exit 1
        fi
        
        # On first boot, gravity.db doesn't exist yet - we need to run pihole -g to create it
        if [ ! -f "$GRAVITY_DB" ]; then
          echo "First boot detected - initializing gravity database..."
          # Run gravity update to create the database
          # This downloads blocklists and creates gravity.db
          sudo -u pihole $PIHOLE_CMD -g || {
            echo "Initial gravity update failed (this may be normal on first boot)"
            echo "Will retry on next boot or manual 'pihole -g'"
            exit 0  # Don't fail - allow system to come up
          }
        fi
        
        # Wait for database to be ready after gravity update
        echo "Waiting for gravity database..."
        for i in {1..30}; do
          if [ -f "$GRAVITY_DB" ] && ${pkgs.sqlite}/bin/sqlite3 "$GRAVITY_DB" "SELECT COUNT(*) FROM adlist LIMIT 1;" 2>/dev/null; then
            echo "Gravity database ready!"
            break
          fi
          sleep 2
        done
        
        if [ ! -f "$GRAVITY_DB" ]; then
          echo "Gravity database not created. Adlists will be configured on next boot."
          exit 0
        fi
        
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
        
        # Update gravity to download the new adlists
        echo "Updating gravity to download adlists..."
        if sudo -u pihole $PIHOLE_CMD -g 2>&1; then
          echo "Gravity update complete!"
        else
          echo "Warning: Gravity update had issues. Adlists are saved and will be downloaded on next update."
        fi
        
        echo "Adlists setup complete!"
      ''}/bin/pihole-adlists-setup";
    };
  };
}

