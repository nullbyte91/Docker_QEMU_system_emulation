## i386
```bash
# Dep 
sudo apt-get install -y qemu-system-i386

# Build
docker build --platform linux/i386 --rm --tag i386:v1 -f i386.Dockerfile .
```
