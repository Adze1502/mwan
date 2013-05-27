#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mwan3
PKG_VERSION:=1.0
PKG_RELEASE:=4

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-mwan3
  SECTION:=luci
  CATEGORY:=LuCI
  DEPENDS:=+mwan3
  TITLE:=LuCI - Lua Configuration Interface
  URL:=http://213.136.13.52/luci-app-mwan3_$(PKG_VERSION)-$(PKG_RELEASE).ipk
  MAINTAINER:=Jeroen Louwes <jeroen.louwes@gmail.com>
  SUBMENU:=3. Applications
  TITLE:=LuCI Support for mwan3 multiwan policy routing
endef

define Package/luci-app-mwan3/description
A hotplug script that makes configuration of multiple WAN interfaces simple, easy and manageable. With load balancing support, connection tracking with failover and an easy to manage traffic ruleset.
endef

define Build/Compile
endef

define Package/luci-app-mwan3/install
	$(CP) ./files/* $(1)
endef

$(eval $(call BuildPackage,luci-app-mwan3))
