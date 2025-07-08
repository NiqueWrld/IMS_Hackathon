# Paths to Conda and activate script
$condaPath = "C:\ProgramData\Anaconda3\Scripts\conda.exe"
$activateScript = "C:\ProgramData\Anaconda3\Scripts\activate.bat"
$envName = "envIMS"

# Use current script directory as target
$targetDir = $PSScriptRoot
$codeCmd = "code"  # VS Code command, must be in PATH

# Python executable path in envIMS
$pythonPath = "$env:USERPROFILE\.conda\envs\$envName\python.exe"

# Check Conda exists
if (-Not (Test-Path $condaPath)) {
    Write-Error "Conda not found at $condaPath. Please check your installation path."
    exit 1
}

# Check VS Code CLI exists
if (-Not (Get-Command $codeCmd -ErrorAction SilentlyContinue)) {
    Write-Error "VS Code CLI ('code') is not available. Make sure it's in your PATH."
    exit 1
}

Write-Host "Creating conda environment $envName..."
& $condaPath create --name $envName python=3.9.18 -y

Write-Host "Activating environment and installing packages..."
cmd.exe /c "`"$activateScript`" $envName && pip install tensorflow ipykernel pandas matplotlib scipy && python -m ipykernel install --user --name $envName --display-name $envName && conda install -c conda-forge notebook -y"

# Install VS Code extensions
Write-Host "Installing VS Code extensions (Python, Jupyter, Pylance)..."
$extensions = @(
    "ms-python.python",
    "ms-toolsai.jupyter",
    "ms-python.vscode-pylance"
)
foreach ($ext in $extensions) {
    Write-Host " → Installing: $ext"
    & $codeCmd --install-extension $ext --force
}

# Create VS Code settings for auto kernel selection
$vsCodeDir = Join-Path $targetDir ".vscode"
if (-Not (Test-Path $vsCodeDir)) {
    New-Item -ItemType Directory -Path $vsCodeDir | Out-Null
}

$settingsPath = Join-Path $vsCodeDir "settings.json"
$settingsContent = @{
    "python.defaultInterpreterPath" = $pythonPath
    "jupyter.kernels.filter" = @(@{ "name" = $envName })
    "terminal.integrated.defaultProfile.windows" = "Command Prompt"
    "terminal.integrated.profiles.windows" = @{
        "Command Prompt" = @{
            "path" = "${env:windir}\System32\cmd.exe"
            "args" = @("/K", "$activateScript $envName")
        }
    }
} | ConvertTo-Json -Depth 5

Set-Content -Path $settingsPath -Value $settingsContent -Encoding UTF8

Write-Host "✅ VS Code settings created at $settingsPath"

# Full path to the file you want to open
$notebookPath = Join-Path $targetDir "IMSTemplate.ipynb"

# Launch VS Code in the folder and open the notebook file
Write-Host "Opening VS Code in $targetDir and opening IMSTemplate.ipynb..."
Start-Process $codeCmd -ArgumentList "`"$targetDir`"", "`"$notebookPath`""


Write-Host "`n🎉 All done! Environment '$envName' is set up, extensions installed, and VS Code is ready with the right interpreter!"
