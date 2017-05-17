Required changes for OpenVPN on EdgeRouter:
```diff
[edit firewall]
+name OVPN_IN {
+    default-action drop
+    rule 1 {
+        action accept
+        destination {
+            address 192.168.1.0/24
+        }
+    }
+}
+name OVPN_LOCAL {
+    default-action drop
+    rule 1 {
+        action accept
+        destination {
+            port 53
+        }
+        protocol udp
+    }
+}
[edit firewall name WAN_LOCAL]
+rule 33 {
+    action accept
+    destination {
+        port 1194
+    }
+    protocol udp
+    state {
+        new enable
+    }
+}
[edit interfaces]
+openvpn vtun0 {
+    config-file /config/openvpn/vpn.example.com.conf
+    firewall {
+        in {
+            name OVPN_IN
+        }
+        local {
+            name OVPN_LOCAL
+        }
+    }
+}
[edit service nat]
+rule 1000 {
+    description "443 Redirect for OpenVPN"
+    destination {
+        port 443
+    }
+    inbound-interface eth0
+    inside-address {
+        port 1194
+    }
+    protocol udp
+    type destination
+}
```

IPTables changes on vpn.example.net:

```diff
--- iptables.old        2017-05-17 19:50:41.641053304 +0000
+++ iptables    2017-05-17 16:08:06.043401689 +0000
@@ -1,15 +1,29 @@
-# Generated by iptables-save v1.4.21 on Wed May 17 19:48:04 2017
+# Generated by iptables-save v1.4.21 on Wed May 17 16:08:06 2017
 *filter
 :INPUT ACCEPT [0:0]
 :FORWARD ACCEPT [0:0]
-:OUTPUT ACCEPT [364322:462453314]
+:OUTPUT ACCEPT [23808:22624551]
 -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
 -A INPUT -p icmp -j ACCEPT
 -A INPUT -i lo -j ACCEPT
 -A INPUT -p tcp -m conntrack --ctstate NEW -m tcp --dport 22 -j ACCEPT
 -A INPUT -p tcp -m conntrack --ctstate NEW -m tcp --dport 9002 -m comment --comment "Weechat WP proxy" -j ACCEPT
 -A INPUT -p tcp -m conntrack --ctstate NEW -m tcp --dport 9001 -m comment --comment "Weechat IRC proxy" -j ACCEPT
+-A INPUT -p udp -m conntrack --ctstate NEW -m udp --dport 1194 -m comment --comment OpenVPN -j ACCEPT
+-A INPUT -i tun0 -p udp -m conntrack --ctstate NEW -m udp --dport 53 -m comment --comment "DNSMasq for OpenVPN" -j ACCEPT
 -A INPUT -j REJECT --reject-with icmp-host-prohibited
+-A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
+-A FORWARD -s 10.8.0.0/24 -i tun0 -o eth0 -m conntrack --ctstate NEW -j ACCEPT
 -A FORWARD -j REJECT --reject-with icmp-host-prohibited
 COMMIT
-# Completed on Wed May 17 19:48:04 2017
+# Completed on Wed May 17 16:08:06 2017
+# Generated by iptables-save v1.4.21 on Wed May 17 16:08:06 2017
+*nat
+:PREROUTING ACCEPT [617:30419]
+:INPUT ACCEPT [108:6402]
+:OUTPUT ACCEPT [141:9956]
+:POSTROUTING ACCEPT [141:9956]
+-A PREROUTING -i eth0 -p udp -m udp --dport 443 -j REDIRECT --to-ports 1194
+-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
+COMMIT
+# Completed on Wed May 17 16:08:06 2017
```