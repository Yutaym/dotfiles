^Space:: {
    localAppData := EnvGet("LOCALAPPDATA")
    exePath := localAppData "\Microsoft\WindowsApps\PowerToys.Run.exe"
    Run('"' exePath '"')
}
