Invoke-Expression (&starship init powershell)

# Funktion statt Alias – weil Aliase keine Argumente unterstützen
function ls { command ls --color=auto --hyperlink @args }
function rg { command rg --hyperlink-format=kitty @args }
function delta { command delta --hyperlinks --hyperlinks-file-link-format="file://{path}#{line}" @args }

$env:LESS = "-R"


# Toggle Vi/Emacs mode
function Toggle-ViMode {
  $current = (Get-PSReadLineOption).EditMode
  if ($current -eq 'Vi') {
    Set-PSReadLineOption -EditMode Emacs
    Write-Host "Switched to Emacs mode"
  } else {
    Set-PSReadLineOption -EditMode Vi
    Write-Host "Switched to Vi mode"
  }
}

Set-PSReadLineKeyHandler -Key Alt+v -ScriptBlock { Toggle-ViMode }

# Copy last output to clipboard
function Copy-LastOutput {
  try {
    $last = (Get-History)[-1].CommandLine
    $result = Invoke-Expression $last
    $result | clip
    Write-Host "Output copied to clipboard from: $last"
  }
  catch {
    Write-Host "Error copying output"
  }
}

Set-PSReadLineKeyHandler -Key Alt+c -ScriptBlock { Copy-LastOutput }

# open file or folder
function Open-Explorer {
  param (
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    Write-Host "Pfad existiert nicht: $Path" -ForegroundColor Red
    return
  }

  $fullPath = (Resolve-Path $Path).Path

  if (Test-Path $fullPath -PathType Leaf) {
    Start-Process "explorer.exe" "/select,`"$fullPath`""
  } elseif (Test-Path $fullPath -PathType Container) {
    Start-Process "explorer.exe" "`"$fullPath`""
  }
}
