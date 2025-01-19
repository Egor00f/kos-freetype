# freetype for kolibrios

This is freetype library from kolibrios repository.

## Build

### install depends:

```
sudo mkdir -p /etc/apt/keyrings
sudo curl https://git.kolibrios.org/api/packages/Egor00f/debian/repository.key -o /etc/apt/keyrings/gitea-Egor00f.asc
echo "deb [signed-by=/etc/apt/keyrings/gitea-Egor00f.asc] https://git.kolibrios.org/api/packages/Egor00f/debian bookworm main" | sudo tee -a /etc/apt/sources.list.d/gitea.list
sudo apt update
sudo apt install kos32-gcc kos-newlib
```

### Build targets

static library:
```
make libfreetype.a
```

shared library:
```
make freetype.dll
```

package:
```
make kos-freetype-dev
```
