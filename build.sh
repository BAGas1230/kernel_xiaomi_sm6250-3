 
#!/bin/bash
#
# Copyright (C) 2020 azrim.
# All rights reserved.

# Init
KERNEL_DIR="${PWD}"
CODENAME="kentot"
tanggal=$(TZ=Asia/Jakarta date "+%Y%m%d-%H%M")
DTB_TYPE="double" # define as "single" if want use single file
KERN_IMG="${KERNEL_DIR}"/out/arch/arm64/boot/Image.gz # if use single file define as Image.gz-dtb instead
KERN_DTB="${KERNEL_DIR}"/out/arch/arm64/boot/dtbo.img # and comment this variable
ANYKERNEL="/home/ricoayuba/BuildKernel/AnyKernel3/"

# Repo URL
CLANG_REPO="https://github.com/silont-project/silont-clang"
ANYKERNEL_REPO="https://github.com/ricoayuba/AnyKernel3"
ANYKERNEL_BRANCH="jayus"

# Compiler
COMP_TYPE="proton-clang" # unset if want to use gcc as compiler
CLANG_DIR="/home/ricoayuba/proton-clang"
#if ! [ -d "${CLANG_DIR}" ]; then


# Defconfig
DEFCONFIG="cust_defconfig"
REGENERATE_DEFCONFIG="true" # unset if don't want to regenerate defconfig

# Costumize
KERNEL="memek"
DEVICE="Miatoll"
KERNELTYPE="AOSP-Q"
KERNELNAME="${KERNEL}-${DEVICE}-${tanggal}"
ZIPNAME="${KERNELNAME}.zip"


# Regenerating Defconfig
regenerate() {
    cp out/.config arch/arm64/configs/"${DEFCONFIG}"
    git add arch/arm64/configs/"${DEFCONFIG}"
    git commit -m "defconfig: Regenerate"
}

# Building
makekernel() {
    export PATH="${COMP_PATH}"
    rm -rf "${KERNEL_DIR}"/out/arch/arm64/boot # clean previous compilation
    mkdir -p out
    make O=out mrproper
    make O=out ARCH=arm64 ${DEFCONFIG}
    if [[ "${REGENERATE_DEFCONFIG}" =~ "true" ]]; then
        regenerate
    fi
    if [[ "${COMP_TYPE}" =~ "clang" ]]; then
        make -j$(nproc --all) O=out \
                ARCH=arm64 \
                CC=clang \
                LOCALVERSION="-${CODENAME}-${tanggal}" \
                LD=ld.lld \
                AR=llvm-ar \
				NM=llvm-nm \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip \
				OBJCOPY=llvm-objcopy \
				OBJSIZE=llvm-size \
				READELF=llvm-readelf \
				CROSS_COMPILE=aarch64-linux-gnu- \
				CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    else
	make -j$(nproc --all) O=out \
				ARCH=arm64 \
				LD=ld.lld \
				AR=aarch64-elf-ar \
				CROSS_COMPILE_ARM32=arm-eabi- \
				CROSS_COMPILE=aarch64-elf- \
				LOCALVERSION="-${CODENAME}-${tanggal}" \
				NM=aarch64-elf-nm \
				OBJCOPY=aarch64-elf-objcopy \
				OBJDUMP=aarch64-elf-objdump \
				OBJSIZE=aarch64-elf-size \
				READELF=aarch64-elf-readelf \
				STRIP=aarch64-elf-strip
    fi
    # Check If compilation is success
    if ! [ -f "${KERN_IMG}" ]; then
	    END=$(date +"%s")
	    DIFF=$(( END - START ))
	    echo -e "Kernel compilation failed, See buildlog to fix errors"
	    tg_cast "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check Instance for errors @Farizmaulana"
	    exit 1
    fi
}

# Packing kranul
packingkernel() {
    # Copy compiled kernel
    if [ -d "${ANYKERNEL}" ]; then
        rm -rf "${ANYKERNEL}"/Image.gz-dtb
    fi
#    git clone "$ANYKERNEL_REPO" -b "$ANYKERNEL_BRANCH" "${ANYKERNEL}"
    if [[ "${DTB_TYPE}" =~ "single" ]]; then
        cp "${KERN_IMG}" "${ANYKERNEL}"/Image.gz
    else
        cp "${KERN_IMG}" "${ANYKERNEL}"/Image.gz
        cp "${KERN_DTB}" "${ANYKERNEL}"/dtbo.img
    fi

	# Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
	rm -rf *.zip
    zip -r9 "${ZIPNAME}" ./*
}

# Starting
tg_cast "<b>STARTING KERNEL BUILD</b>" \
  "Compiler: <code>${COMP_TYPE}</code>" \
	"Device: ${DEVICE}" \
	"Kernel: <code>${KERNEL}, ${KERNELTYPE}</code>" \
	"Linux Version: <code>$(make kernelversion)</code>"
START=$(date +"%s")
makekernel
packingkernel
END=$(date +"%s")
DIFF=$(( END - START ))
tg_cast "Build for ${DEVICE} with ${COMPILER_STRING} <b>succeed</b> took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! @Farizmaulana"