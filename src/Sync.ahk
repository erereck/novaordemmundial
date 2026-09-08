SyncAssets(force := false) {
    global CFG, CACHEDIR

    configVersion := IniRead(CFG, "General", "Version", "0")
    marker := CACHEDIR "\assets.version"
    cachedVersion := ""

    if FileExist(marker) {
        try {
            cachedVersion := Trim(FileRead(marker))
        } catch {
            cachedVersion := ""
        }
    }

    ; Se a configuracao mudou, os arquivos com o mesmo nome tambem podem ter
    ; mudado de URL. Forca a troca somente nessa primeira abertura da versao.
    if (cachedVersion != configVersion)
        force := true

    EnsureAsset(
        IniRead(CFG, "General", "WallpaperURL", ""),
        IniRead(CFG, "General", "WallpaperFile", ""),
        force
    )

    EnsureAsset(
        IniRead(CFG, "General", "GamesIconURL", ""),
        IniRead(CFG, "General", "GamesIconFile", ""),
        force
    )

    EnsureAsset(
        IniRead(CFG, "Special", "IconURL", ""),
        IniRead(CFG, "Special", "IconFile", ""),
        force
    )

    SyncSectionAssets("Home", force)
    SyncSectionAssets("Game", force)

    try {
        if FileExist(marker)
            FileDelete(marker)
        FileAppend(configVersion, marker, "UTF-8")
    } catch {
    }
}

SyncSectionAssets(prefix, force := false) {
    global CFG

    count := Integer(IniRead(CFG, "General", prefix "Count", "0"))
    Loop count {
        sec := prefix A_Index
        EnsureAsset(
            IniRead(CFG, sec, "IconURL", ""),
            IniRead(CFG, sec, "IconFile", ""),
            force
        )
    }
}

EnsureAsset(url, fileName, force := false) {
    global ASSETDIR

    if (url = "" || fileName = "")
        return false

    path := ASSETDIR "\" fileName
    if FileExist(path) && !force
        return true

    temp := path ".download"

    try {
        if FileExist(temp)
            FileDelete(temp)

        Download(url, temp)

        if !FileExist(temp)
            return false

        ; So apaga o asset anterior DEPOIS que o novo terminou de baixar.
        ; Se a internet cair, o launcher continua com o ultimo arquivo valido.
        if FileExist(path)
            FileDelete(path)

        FileMove(temp, path, 1)
        return true
    } catch {
        if FileExist(temp) {
            try {
                FileDelete(temp)
            } catch {
            }
        }
        return false
    }
}

SyncNow() {
    global SETTINGS, CACHECFG, CACHEDIR

    url := IniRead(SETTINGS, "Sync", "RemoteConfigURL", "")
    if (url = "")
        return false

    temp := CACHEDIR "\download.tmp.ini"

    try {
        if FileExist(temp)
            FileDelete(temp)

        Download(url, temp)

        if (IniRead(temp, "General", "Version", "") = "")
            throw Error("config invalido")

        if (IniRead(temp, "General", "Title", "") = "")
            throw Error("config invalido")

        FileCopy(temp, CACHECFG, true)
        FileDelete(temp)
        return true
    } catch {
        if FileExist(temp) {
            try {
                FileDelete(temp)
            } catch {
            }
        }
        return false
    }
}

ChooseConfig() {
    global CFG, CACHECFG, LOCALCFG

    if !FileExist(CACHECFG) {
        CFG := LOCALCFG
        return
    }

    ; Um cache remoto antigo nao pode esconder uma versao nova que veio no
    ; git/ZIP. Usa a configuracao de maior versao entre local e cache.
    localVersion := VersionNumber(IniRead(LOCALCFG, "General", "Version", "0"))
    cacheVersion := VersionNumber(IniRead(CACHECFG, "General", "Version", "0"))

    CFG := localVersion >= cacheVersion ? LOCALCFG : CACHECFG
}

VersionNumber(value) {
    try {
        return Integer(value)
    } catch {
        return 0
    }
}

CheckUpdate() {
    global CFG, CACHECFG, CFG_VERSION

    if !SyncNow()
        return

    newVersion := IniRead(CACHECFG, "General", "Version", "0")
    if (VersionNumber(newVersion) <= VersionNumber(CFG_VERSION))
        return

    CFG := CACHECFG
    CFG_VERSION := newVersion
    SyncAssets(true)
    BuildUI()
}
