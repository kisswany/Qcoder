$files = @(
 "pubspec.yaml",
 "android\app\src\main\AndroidManifest.xml",
 "lib\main.dart",
 "lib\screens\about_screen.dart",
 "lib\screens\home\home_screen.dart",
 "lib\screens\home\tabs\generator_tab.dart",
 "lib\screens\home\tabs\scanner_tab.dart",
 "lib\screens\home\views\result_view.dart",
 "lib\utils\ui_utils.dart",
 "lib\widgets\buttons.dart",
 "lib\widgets\scanner_overlay.dart"
)
$out = "C:\Users\kissw\.gemini\antigravity\brain\b1e1de39-72b0-418f-abb2-eb903e859a26\project_context.md"

foreach ($f in $files) {
  Add-Content -Path $out -Value "`n================================================================`nFile: $f`n================================================================`n"
  Get-Content -Path $f -Raw | Add-Content -Path $out
}
Write-Host "Aggregation complete."
