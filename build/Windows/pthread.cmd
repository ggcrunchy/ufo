@echo off
call %~dp0/wdk/setup %~n0 %*
pushd %LB_PROJECT_ROOT%
setlocal

set NAME=%LB_PROJECT_NAME%

cl -Fe%NAME%.dll -DHAVE_CONFIG_H -D_MSC_VER=1399 -DPTW32_BUILD=1 -DPTW32_BUILD_INLINED -I. %NAME%.c -LD %LB_CL_OPTS% /link"%LB_LINK_OPTS%"

call %~dp0/wdk/install %NAME%.dll
call %~dp0/wdk/install %NAME%.lib
call %~dp0/wdk/install %NAME%.pdb
endlocal
popd
