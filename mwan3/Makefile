#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mwan3
PKG_VERSION:=1.3
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

define Package/mwan3
   SECTION:=net
   CATEGORY:=Network
   DEPENDS:=+ip +iptables +iptables-mod-conntrack-extra +iptables-mod-ipopt
   TITLE:=A multiwan hotplug script with connection tracking support
   MAINTAINER:=Jeroen Louwes <jeroen.louwes@gmail.com>
   PKGARCH:=all
endef

define Package/mwan3/description
   A hotplug script that makes configuration of multiple WAN interfaces simple, easy and manageable. With load balancing support, connection tracking with failover and an easy to manage traffic ruleset.
endef

define Package/mwan3/conffiles
   /etc/config/mwan3
endef

define Build/Compile
endef

define Package/mwan3/install
   $(CP) ./files/* $(1)
endef

define Package/mwan3/postinst
   [ -n "$${IPKG_INSTROOT}" ] || /etc/init.d/mwan3 enable
   exit 0
endef

$(eval $(call BuildPackage,mwan3))
