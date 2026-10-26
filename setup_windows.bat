@echo off
setlocal
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter was not found. Install Flutter and add flutter\bin to PATH first.
  pause
  exit /b 1
)
if not exist android\ (
  echo Creating the Android runner files...
  flutter create --platforms=android --project-name farmdirect .
  if errorlevel 1 goto failed
)
echo Fetching dependencies...
flutter pub get
if errorlevel 1 goto failed
echo Running static analysis...
flutter analyze
if errorlevel 1 goto failed
echo Running tests...
flutter test
if errorlevel 1 goto failed
echo.
echo Setup checks completed successfully. Run flutter run to launch the app.
pause
exit /b 0
:failed
echo A command failed. Read the error above and fix the Flutter environment or project issue.
pause
exit /b 1
