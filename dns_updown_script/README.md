##### Purpose:

This script is to be used as an up/down script for OpenVPN on the GL-AR300M pocket router. The [GL-AR300M](https://www.gl-inet.com/ar300m/) compact router support OpenVPN out of the box, but unless you painstakingly set custom DNS to something that's both public to YOU pre/post VPN, it will leak DNS to the LAN. Ideally what we want to do is use the DNS available to us over the tunnel local to that network (for several reasons, security, views, etc).

See: [This forum post](https://www.gl-inet.com/forums/topic/dns-not-changing-after-openvpn-connection-starts/#post-70471) for further information. 

##### Instructions:

1. Place the script in `/etc/openvpn/`
2. Edit your conf or ovpn to include:
   ```
   up /etc/openvpn/dns_updown_script.sh
   down /etc/openvpn/dns_updown_script.sh
   ```
  
 The variable `$script_type` is already populated by OpenVPN before it runs the script, which is how I'm running each function of the script - this way no arguments are needed.
 
 
