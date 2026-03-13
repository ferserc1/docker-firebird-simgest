#!/bin/sh
set -e

fb_install_prefix=/opt/firebird
default_prefix=/opt/firebird
RunUser=firebird
RunGroup=firebird
PidDir=/var/run/firebird
SecurityDatabase=security3.fdb
DefaultLibrary=libfbclient
Manifest=manifest.txt
MANIFEST_TXT=""
ArchiveDateTag=$(date +"%Y%m%d_%H%M")
ArchiveMainFile="${fb_install_prefix}_${ArchiveDateTag}"
origDir=$(pwd)

Add2Path() {
    Dir="${1}"
    x=$(echo ":${PATH}:" | grep ":$Dir:" || true)
    if [ -z "$x" ]; then
        PATH=$PATH:$Dir
        export PATH
    fi
}

Add2Path /usr/sbin
Add2Path /sbin

MakeTemp() {
    TmpFile=$(mktemp -q /tmp/firebird_install.XXXXXX 2>/dev/null || true)
    if [ -z "$TmpFile" ]; then
        for n in $(seq 1000); do
            TmpFile=/tmp/firebird_install.$n
            if [ ! -e "$TmpFile" ]; then
                touch "$TmpFile"
                return
            fi
        done
    fi
}

runSilent() {
    MakeTemp
    rm -f "$TmpFile"
    sh -c "$1" >>"$TmpFile" 2>>"$TmpFile"
    if [ $? -ne 0 ]; then
        cat "$TmpFile"
        echo ""
        rm -f "$TmpFile"
        return 1
    fi
    rm -f "$TmpFile"
    return 0
}

checkInstallUser() {
    if [ "$(whoami)" != "root" ]; then
        echo "You need to be root to install Firebird"
        exit 1
    fi
}

grepProcess() {
    ps -efaww | egrep "\<($1)(\$|[[:space:]])" | grep -v grep | grep -v -w '\-path' || true
}

stopSuperServerIfRunning() {
    checkString=$(grepProcess "fbserver|fbguard|fb_smp_server|firebird")
    if [ -n "$checkString" ]; then
        echo "A Firebird server appears to be running. Stop it before building the image."
        exit 1
    fi
}

checkIfServerRunning() {
    stopSuperServerIfRunning

    checkString=$(grepProcess "ibserver|ibguard")
    if [ -n "$checkString" ]; then
        echo "An InterBase/Firebird server appears to be running."
        exit 1
    fi

    checkString=$(grepProcess "gds_inet_server|gds_pipe|fb_inet_server")
    if [ -n "$checkString" ]; then
        echo "A Classic server appears to be running."
        exit 1
    fi
}

haveLibrary() {
    libName="${1}"
    [ -z "$libName" ] && return 1

    ldconfig -p | grep -w "$libName" >/dev/null 2>/dev/null && return 0

    libName="lib${libName}"
    ldconfig -p | grep -w "$libName" >/dev/null 2>/dev/null
}

checkLibrary() {
    libName="${1}"
    if ! haveLibrary "$libName"; then
        echo "Please install required library '$libName' before Firebird"
        exit 1
    fi
}

checkLibraries() {
    checkLibrary tommath
    checkLibrary icudata
}

replaceLineInFile() {
    FileName="$1"
    newLine="$2"
    oldLine=$(grep "$3" "$FileName" 2>/dev/null || true)

    if [ -z "$oldLine" ]; then
        echo "$newLine" >> "$FileName"
    elif [ "$oldLine" != "$newLine" ]; then
        MakeTemp
        grep -v "$oldLine" "$FileName" > "$TmpFile"
        echo "$newLine" >> "$TmpFile"
        cp "$TmpFile" "$FileName"
        rm -f "$TmpFile"
    fi
}

editFile() {
    FileName="$1"
    Starting="$2"
    NewLine="$3"

    AwkProgram="(/^$Starting.*/ || \$1 == \"$Starting\") {\$0=\"$NewLine\"} {print \$0}"
    MakeTemp
    awk "$AwkProgram" <"$FileName" >"$TmpFile"
    mv "$TmpFile" "$FileName"
}

TryAddGroup() {
    AdditionalParameter="$1"
    testStr=$(grep "$RunGroup" /etc/group || true)

    if [ -z "$testStr" ]; then
        groupadd $AdditionalParameter "$RunGroup"
    fi
}

TryAddUser() {
    AdditionalParameter="$1"
    testStr=$(grep "$RunUser" /etc/passwd || true)

    if [ -z "$testStr" ]; then
        useradd $AdditionalParameter -d "${fb_install_prefix}" -s /sbin/nologin \
            -c "Firebird Database Owner" -g "$RunUser" "$RunGroup"
    fi
}

addFirebirdUser() {
    TryAddGroup "-g 84 -r" >/dev/null 2>/dev/null || true
    TryAddGroup "-g 84" >/dev/null 2>/dev/null || true
    TryAddGroup "-r" >/dev/null 2>/dev/null || true
    TryAddGroup " " >/dev/null 2>/dev/null || true

    TryAddUser "-u 84 -r -M" >/dev/null 2>/dev/null || true
    TryAddUser "-u 84 -M" >/dev/null 2>/dev/null || true
    TryAddUser "-r -M" >/dev/null 2>/dev/null || true
    TryAddUser "-M" >/dev/null 2>/dev/null || true
    TryAddUser "-u 84 -r" >/dev/null 2>/dev/null || true
    TryAddUser "-u 84" >/dev/null 2>/dev/null || true
    TryAddUser "-r" >/dev/null 2>/dev/null || true
    TryAddUser " " >/dev/null 2>/dev/null || true
}

createNewPassword() {
    NewPasswd=""
    openssl </dev/null >/dev/null 2>/dev/null || true
    if [ $? -eq 0 ]; then
        NewPasswd=$(openssl rand -base64 40 | tr -d '/' | cut -c1-20)
    fi

    if [ -z "$NewPasswd" ]; then
        NewPasswd=$(dd if=/dev/urandom bs=10 count=1 2>/dev/null | od -x | head -n 1 | tr -d ' ' | cut -c8-27)
    fi

    if [ -z "$NewPasswd" ]; then
        NewPasswd="masterkey"
    fi

    echo "$NewPasswd"
}

writeNewPassword() {
    NewPasswd="$1"
    DBAPasswordFile="${fb_install_prefix}/SYSDBA.password"
    FB_HOST=$(hostname)
    FB_TIME=$(date)

    cat <<EOT >"$DBAPasswordFile"
#
# Firebird generated password for user SYSDBA is:
#
ISC_USER=sysdba
ISC_PASSWORD=$NewPasswd
#
# Also set legacy variable though it can't be exported directly
#
ISC_PASSWD=$NewPasswd
#
# generated on $FB_HOST at time $FB_TIME
#
EOT

    chmod u=r,go= "$DBAPasswordFile"
}

setDBAPassword() {
    passwd=$(createNewPassword)
    [ -z "$passwd" ] && passwd=masterkey

    runSilent "${fb_install_prefix}/bin/gsec -add sysdba -pw $passwd"
    writeNewPassword "$passwd"
}

newManifest() {
    ExistingManifestFile="${1}"
    CreateManifestFile="${2}"

    rm -f "$CreateManifestFile"
    oldPath=".${default_prefix}"

    grep "^${oldPath}" "$ExistingManifestFile" | while read -r line; do
        suffix=$(echo "$line" | colrm 1 ${#oldPath})
        echo ".${fb_install_prefix}${suffix}" >>"$CreateManifestFile"
    done

    newPath=$(dirname "${fb_install_prefix}")
    while [ ${#newPath} -gt 1 ]; do
        echo ".${newPath}" >>"$CreateManifestFile"
        newPath=$(dirname "$newPath")
    done
}

archivePriorInstallSystemFiles() {
    :
}

extractBuildroot() {
    if [ "${fb_install_prefix}" = "${default_prefix}" ]; then
        cd /
        tar -xzof "$origDir/buildroot.tar.gz"
    else
        mkdir -p "${fb_install_prefix}"
        cd "${fb_install_prefix}"
        defDir=".${default_prefix}"

        tar -xzof "$origDir/buildroot.tar.gz" "${defDir}"
        for p in ${defDir}/*; do
            mv "$p" .
        done

        while [ ${#defDir} -gt 2 ]; do
            rm -rf "${defDir}"
            defDir=$(dirname "$defDir")
        done
    fi

    cd "$origDir"
}

setNewPrefix() {
    binlist="${fb_install_prefix}/bin/changeServerMode.sh ${fb_install_prefix}/bin/fb_config ${fb_install_prefix}/bin/registerDatabase.sh ${fb_install_prefix}/bin/FirebirdUninstall.sh"
    filelist="$binlist ${fb_install_prefix}/misc/firebird.init.d.*"

    for file in $filelist; do
        [ -f "$file" ] && editFile "$file" fb_install_prefix "fb_install_prefix=${fb_install_prefix}"
    done

    for file in $binlist; do
        [ -f "$file" ] && chmod 0700 "$file"
    done
}

MakeFileFirebirdWritable() {
    FileName="$1"
    chown "$RunUser:$RunGroup" "$FileName"
    chmod ug=rw,o= "$FileName"
}

fixFilePermissions() {
    chown -R root:root "${fb_install_prefix}"

    touch "${fb_install_prefix}/fb_guard"
    MakeFileFirebirdWritable "${fb_install_prefix}/fb_guard"

    touch "${fb_install_prefix}/firebird.log"
    MakeFileFirebirdWritable "${fb_install_prefix}/firebird.log"

    MakeFileFirebirdWritable "${fb_install_prefix}/${SecurityDatabase}"

    if [ -d "${fb_install_prefix}/examples/empbuild" ]; then
        find "${fb_install_prefix}/examples/empbuild" -name '*.fdb' -print | while read -r i; do
            MakeFileFirebirdWritable "$i"
        done
    fi

    if [ -f "${fb_install_prefix}/help/help.fdb" ]; then
        chmod a=r "${fb_install_prefix}/help/help.fdb"
    fi
}

buildUninstallFile() {
    if [ ! -f "$origDir/$Manifest" ]; then
        return
    fi

    MANIFEST_TXT="${fb_install_prefix}/misc/$Manifest"
    mkdir -p "${fb_install_prefix}/misc"

    if [ "${fb_install_prefix}" = "${default_prefix}" ]; then
        cp "$origDir/$Manifest" "$MANIFEST_TXT"
    else
        newManifest "$origDir/$Manifest" "$MANIFEST_TXT"
    fi

    [ -f "${fb_install_prefix}/bin/FirebirdUninstall.sh" ] && chmod u=rx,go= "${fb_install_prefix}/bin/FirebirdUninstall.sh"
}

CorrectLibDir() {
    ld="${1}"
    l=/usr/lib
    l64=/usr/lib64

    if [ "$ld" = "$l64" ] && [ -d "$l" ] && [ ! -d "$l64" ]; then
        ld="$l"
    fi

    echo "$ld"
}

removeIfOnlyAlink() {
    Target="$1"
    [ -L "$Target" ] && rm -f "$Target"
}

safeLink() {
    Source="$1"
    Target="$2"

    if [ "$Source" = "$Target" ] || [ "${fb_install_prefix}" != "${default_prefix}" ]; then
        return 0
    fi

    if [ -L "$Target" ]; then
        rm -f "$Target"
    fi

    if [ -e "$Target" ]; then
        return 0
    fi

    ln -s "$Source" "$Target"
}

reconfigDynamicLoader() {
    ldconfig
}

createLinksInSystemLib() {
    LibDir=$(CorrectLibDir /usr/lib64)
    mkdir -p "$LibDir"

    cd "${fb_install_prefix}/lib"
    for l in libfbclient.so* libib_util.so; do
        [ -e "$l" ] && safeLink "${fb_install_prefix}/lib/$l" "$LibDir/$l"
    done

    if [ -d "${fb_install_prefix}/lib/.tm" ] && [ ! -f "$LibDir/libtommath.so" ]; then
        cd "${fb_install_prefix}/lib/.tm"
        for l in libtommath.so*; do
            [ -e "$l" ] && safeLink "${fb_install_prefix}/lib/.tm/$l" "$LibDir/$l"
        done
    fi

    reconfigDynamicLoader
}

createLinksForBackCompatibility() {
    newLibrary="${fb_install_prefix}/lib/$DefaultLibrary.so"
    LibDir=$(CorrectLibDir /usr/lib64)
    safeLink "$newLibrary" "$LibDir/libgds.so"
    safeLink "$newLibrary" "$LibDir/libgds.so.0"
}

main() {
    checkInstallUser
    checkIfServerRunning
    checkLibraries
    archivePriorInstallSystemFiles
    extractBuildroot

    replaceLineInFile /etc/services \
        "gds_db          3050/tcp  # Firebird SQL Database Remote Protocol" \
        "^gds_db"

    if [ "$RunUser" = "firebird" ]; then
        addFirebirdUser
    fi

    setNewPrefix
    fixFilePermissions
    buildUninstallFile
    createLinksInSystemLib
    createLinksForBackCompatibility
    setDBAPassword

    echo "Firebird installed successfully without starting the server."
}

main "$@"
