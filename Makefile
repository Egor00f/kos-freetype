LINUX_TOOLCHAIN_PATH = /home/autobuild/tools/win32

PathToFreetype = contrib/sdk/sources/freetype

install libfreetype.a freetype.dll clean:
	$(MAKE) -C $(PathToFreetype) $@

kos-freetype-dev: libfreetype.a freetype.dll
	mkdir -p $@$(LINUX_TOOLCHAIN_PATH)/include
	mkdir -p $@$(LINUX_TOOLCHAIN_PATH)/mingw32/lib

	cp -rf $(PathToFreetype)/include $@$(LINUX_TOOLCHAIN_PATH)
	cp -f $(PathToFreetype)/*.a $@$(LINUX_TOOLCHAIN_PATH)/mingw32/lib

	dpkg-deb --build $@ $@.deb
