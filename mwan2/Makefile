#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mwan2
PKG_VERSION:=1.4
PKG_RELEASE:=5

include $(INCLUDE_DIR)/package.mk

define Package/mwan2
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+ip +iptables +iptables-mod-conntrack-extra +iptables-mod-ipopt
  TITLE:=A multiwan hotplug script with connection tracking support
  URL:=http://213.136.13.52/mwan2_1.4-3.ipk
  MAINTAINER:=Jeroen Louwes <jeroen.louwes@gmail.com>
endef

define Package/mwan2/description
A hotplug script that makes configuration of multiple WAN interfaces simple, easy and manageable. With load balancing support, connection tracking with failover and an easy to manage traffic ruleset.
endef

define Package/mwan2/conffiles
/etc/config/mwan2
endef

define Build/Compile
endef

define Package/mwan2/install
	$(CP) ./files/* $(1)
endef

$(eval $(call BuildPackage,mwan2))
