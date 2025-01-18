LINUX_TOOLCHAIN_PATH = /home/autobuild/tools/win32

PathToFreetype = contrib/sdk/sources/pixman

install libfreetype.a freetype.dll clean:
	$(MAKE) -C $(PathToFreetype) $@

kos-freetype-dev: libcairo2.a cairo2.dll
	mkdir -p $@$(LINUX_TOOLCHAIN_PATH)/include

	cp -rf $(PathToFreetype)/include $@$(LINUX_TOOLCHAIN_PATH)
	cp -f $(PathToFreetype)/*.a $@$(LINUX_TOOLCHAIN_PATH)/mingw32/lib

	dpkg-deb --build $@ $@.deb
