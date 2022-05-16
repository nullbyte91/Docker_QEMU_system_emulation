# Docker_QEMU_system_emulation
## i386
```bash
# Dep 
sudo apt-get install -y qemu-system-i386

# Build
docker build --platform linux/i386 --rm --tag i386:v1 -f i386.Dockerfile .
```

## ARM64
```bash
# Dep
sudo apt-get install -y qemu-user-static

# Build
docker build --rm --tag i386:v1 -f arm64v8.Dockerfile .

# Tensorflow lite
docker build --rm --tag i386:v1 -f arm64v8_tf.Dockerfile .

# ARMNN
docker build --rm --tag i386:v1 -f arm64v8_armnn.Dockerfile .
```