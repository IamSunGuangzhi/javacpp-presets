@echo on
set PROJ=%~1
cd %APPVEYOR_BUILD_FOLDER%

REM Create a writeable TMPDIR
mkdir %APPVEYOR_BUILD_FOLDER%\tmp
set TMPDIR=%APPVEYOR_BUILD_FOLDER%\tmp
mkdir %APPVEYOR_BUILD_FOLDER%\buildlogs

set MAKEJ=2

IF "%OS%"=="windows-x86_64" (
   set MSYSTEM=MINGW64
   echo Callings vcvarsall for amd64
   call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64

)
IF "%OS%"=="windows-x86" (
   set MSYSTEM=MINGW32
   echo Callings vcvarsall for x86
   call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86
)
echo on

rem C:\msys64\usr\bin\bash -lc "pacman -Syu --noconfirm"
rem C:\msys64\usr\bin\bash -lc "pacman -Su --noconfirm"
C:\msys64\usr\bin\bash -lc "pacman -S --needed --noconfirm base-devel git tar nasm yasm pkg-config unzip autoconf automake libtool make patch"
C:\msys64\usr\bin\bash -lc "pacman -S --needed --noconfirm mingw-w64-x86_64-toolchain mingw-w64-x86_64-libtool mingw-w64-x86_64-cmake mingw-w64-x86_64-gcc mingw-w64-i686-gcc mingw-w64-x86_64-gcc-fortran mingw-w64-i686-gcc-fortran mingw-w64-x86_64-libwinpthread-git mingw-w64-i686-libwinpthread-git mingw-w64-x86_64-SDL mingw-w64-i686-SDL"

C:\msys64\usr\bin\bash -lc "/c/projects/javacpp-presets/ci/install-windows.sh %PROJ%"
SET CUDA_PATH=%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v9.1
SET CUDA_PATH_V9_1=%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v9.1
SET PATH=%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v9.1\bin;%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v9.1\libnvvp;C:\msys64\usr\bin\core_perl;C:\msys64\%MSYSTEM%\bin;C:\msys64\usr\bin;%PATH%

echo Building for "%APPVEYOR_REPO_BRANCH%"
echo PR Number "%APPVEYOR_PULL_REQUEST_NUMBER%"
IF "%APPVEYOR_PULL_REQUEST_NUMBER%"=="" (
   echo Deploy snaphot for %PROJ%
   call mvn clean deploy -B -U -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -Djavacpp.platform=%OS% -Djavacpp.platform.extension=%EXT% -Djavacpp.copyResources --settings .\ci\settings.xml -pl .,%PROJ%
   IF ERRORLEVEL 1 (
     echo Quitting with error  
     exit /b 1
   )
   FOR %%a in ("%PROJ:,=" "%") do (
    echo Deploy platform %%a 
    cd %%a
    call mvn clean -B -U -f platform -Djavacpp.platform=%OS% -Djavacpp.platform.extension=%EXT% --settings ..\ci\settings.xml deploy
    IF ERRORLEVEL 1 (
      echo Quitting with error  
      exit /b 1
    )

    cd ..
   )
) ELSE (
   echo Install %PROJ%
   call mvn clean install -B -U -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -Djavacpp.platform=%OS% -Djavacpp.platform.extension=%EXT% -Djavacpp.copyResources -pl .,%PROJ%
   IF ERRORLEVEL 1 (
      echo Quitting with error  
      exit /b 1 
   )

)

