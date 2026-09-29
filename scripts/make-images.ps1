<#
.SYNOPSIS
  Renders manual pages from Lenovo's X1 Yoga Gen 5 / X1 Carbon Gen 8 Hardware
  Maintenance Manual PDF into site/img/, so site/index.html shows its figures.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\make-images.ps1
  powershell -ExecutionPolicy Bypass -File scripts\make-images.ps1 -Pdf C:\path\to\manual.pdf

.NOTES
  Windows 10/11, Windows PowerShell 5.1, no extra installs (uses the built-in
  Windows.Data.Pdf renderer). Default input: manual.pdf in the repo root.
#>
param(
  [string]$Pdf = (Join-Path (Split-Path $PSScriptRoot -Parent) 'manual.pdf'),
  [string]$Out = (Join-Path (Split-Path $PSScriptRoot -Parent) 'site\img'),
  # PDF page index minus printed page number (printed p.71 is PDF page 79)
  [int]$PageOffset = 8,
  [int]$Dpi = 200
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Pdf)) { throw "PDF not found: $Pdf`nCopy the manual to manual.pdf in the repo root, or pass -Pdf <path>." }
$Pdf = (Resolve-Path $Pdf).Path

Add-Type -AssemblyName System.Runtime.WindowsRuntime, System.Drawing
$null = [Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType=WindowsRuntime]
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime]
$null = [Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Storage.Streams, ContentType=WindowsRuntime]

$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
  $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
  $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1
function Await($op, [Type]$type) {
  $t = $asTask.MakeGenericMethod($type).Invoke($null, @($op)); $t.Wait(-1) | Out-Null; $t.Result
}
function AwaitAction($op) {
  $m = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } | Select-Object -First 1
  $t = $m.Invoke($null, @($op)); $t.Wait(-1) | Out-Null
}

$file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Pdf)) ([Windows.Storage.StorageFile])
$doc  = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
Write-Host "Loaded $Pdf ($($doc.PageCount) pages)"

# Render PDF page index (0-based) to a System.Drawing bitmap at $Dpi.
function Render([int]$index) {
  $page = $doc.GetPage($index)
  $opts = New-Object Windows.Data.Pdf.PdfPageRenderOptions
  $opts.DestinationWidth  = [uint32][math]::Round($page.Size.Width  / 96 * $Dpi)
  $opts.DestinationHeight = [uint32][math]::Round($page.Size.Height / 96 * $Dpi)
  $opts.BackgroundColor = [Windows.UI.Color]::FromArgb(255,255,255,255)
  $ms = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
  AwaitAction ($page.RenderToStreamAsync($ms, $opts))
  $page.Dispose()
  $net = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($ms)
  $bmp = New-Object System.Drawing.Bitmap($net)
  $copy = New-Object System.Drawing.Bitmap($bmp)   # detach from the stream
  $bmp.Dispose(); $net.Dispose(); $ms.Dispose()
  $copy
}

New-Item -ItemType Directory -Force -Path $Out, (Join-Path $Out 'full') | Out-Null

# Full pages for the lightbox, named by PDF page number (printed page = PDF page - offset:
# printed pp. 69-76 and 83-84).
$fullPages = 77..84 + 91, 92
# Figure crops: name, printed page, x, y, width, height (pixels at 200 dpi).
$crops = @(
  @{ name='sim';   page=70; x=473; y=1419; w=726; h=319 },
  @{ name='base';  page=72; x=473; y=187;  w=737; h=638 },
  @{ name='card';  page=74; x=473; y=187;  w=737; h=638 },
  @{ name='batt1'; page=76; x=473; y=671;  w=737; h=462 },
  @{ name='batt2'; page=76; x=473; y=1144; w=737; h=484 },
  @{ name='ant';   page=83; x=440; y=1579; w=847; h=457 },
  @{ name='route'; page=84; x=473; y=418;  w=737; h=440 }
)
$cache = @{}
function Page([int]$printed) {
  if (-not $cache.ContainsKey($printed)) { $cache[$printed] = Render ($printed + $PageOffset - 1) }
  $cache[$printed]
}

foreach ($p in $fullPages) {
  $bmp = Page ($p - $PageOffset)
  $bmp.Save((Join-Path $Out "full\p$p.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "full\p$p.png (manual p. $($p - $PageOffset))"
}

foreach ($c in $crops) {
  $rect = New-Object System.Drawing.Rectangle($c.x, $c.y, $c.w, $c.h)
  $img = (Page $c.page).Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $img.Save((Join-Path $Out "$($c.name).png"), [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "$($c.name).png (manual p. $($c.page))"
}
Write-Host "Done. Open site\index.html."

