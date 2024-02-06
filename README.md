# openwrt-ddns-wedos
Wedos Dynamic DNS script for OpenWrt

## Requirements
For OpenWrt 22.03.3 libubox is libubox20220515, check whether another version of libubox is available for your openwrt version
```
$ opkg install libubox20220515
$ opkg install curl
$ opkg install coreutils-sha1sum
$ opkg install ddns-script ddns-services
```

## Installation
Follow [this guide to turn on WEDOS Api](https://kb.wedos.com/cs/wapi-api-rozhrani/zakladni-informace-wapi-api-rozhrani/wapi-aktivace-a-nastaveni/).
Copy `update_wedos_com.sh` to `openwrt:/usr/lib/ddns/update_wedos_com.sh`

Or 
```
wget -O /usr/lib/ddns/update_wedos_com.sh -q https://raw.githubusercontent.com/milokmet/openwrt-ddns-wedos/main/update_wedos_com.sh && chmod +x /usr/lib/ddns/update_wedos_com.sh
```

## Configuration
Example configuration `/etc/config/ddns`
```
config service 'example'
        option enabled '1'
        option update_script '/usr/lib/ddns/update_wedos_com.sh'
        option use_syslog '2'
        option domain 'sub.example.com'
        option ip_source 'network'
        option ip_network 'wan'
        option lookup_host 'sub.example.com'
        # ns.wedos.cz didn't work with openwrt
        option dns_server 'ns.wedos.eu'
        option password 'password'
        option username 'you@example.com'

```
