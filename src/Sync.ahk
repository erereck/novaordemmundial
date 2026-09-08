SyncAssets(force := false) {
    global CFG

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
    CFG := FileExist(CACHECFG) ? CACHECFG : LOCALCFG
}

CheckUpdate() {
    global CFG, CACHECFG, CFG_VERSION

    if !SyncNow()
        return

    newVersion := IniRead(CACHECFG, "General", "Version", "0")
    if (newVersion = CFG_VERSION)
        return

    CFG := CACHECFG
    CFG_VERSION := newVersion
    SyncAssets(true)
    BuildUI()
}
