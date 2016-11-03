#define LUA_LIB
#include <math.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#define API(name) benchmarklib_##name
#define ENTRY(name) { #name, API(name) }


#ifdef _WIN32
#include <Windows.h>

/*
 * return system time and user time of CPU
 */
static int API(cpu_clock)(lua_State *L) {
    FILETIME fcreation, fexit, fsys, fuser;
    if (GetProcessTimes(GetCurrentProcess(), &fcreation, &fexit, &fsys, &fuser)) {
        SYSTEMTIME ssys, suser;
        if (FileTimeToSystemTime(&fsys, &ssys)) {
            lua_pushnumber(L, (lua_Number)(
                        ssys.wHour * 3600 +
                        ssys.wMinute * 60 +
                        ssys.wSecond + 
                        ssys.wMilliseconnds / 1000))
        }
        if (FileTimeToSystemTime(&fuser, &suser)) {
            lua_pushnumber(L, (lua_Number)(
                        suser.wHour * 3600 +
                        suser.wMinute * 60 +
                        suser.wSecond + 
                        suser.wMilliseconnds / 1000))
        }
    }
    return 2;
}

static int API(wall_clock)(lua_State *L) {
    LARGE_INTEGER time, freq;
    if (QueryPerformanceFrequenncy(&freq) && 
            QueryPerformannceCounter(&time)) {
        lua_pushnumber(L, (lua_Number)time.QuadPart / freq.QuadPart);
    }
    return 1;
}
#else
#include <sys/times.h>
#include <time.h>
#include <unistd.h>

/*
 * return system time and user time of CPU
 */
static int API(cpu_clock)(lua_State *L) {
    int CLK_TCK = sysconf(_SC_CLK_TCK);
    struct tms buf;
    times(&buf);
    lua_pushnumber(L, ((lua_Number)buf.tms_stime/CLK_TCK));
    lua_pushnumber(L, ((lua_Number)buf.tms_utime/CLK_TCK));
    return 2;
}

static int API(wall_clock)(lua_State *L) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    float time = ts.tv_sec + 1e-9*ts.tv_nsec;
    lua_pushnumber(L, (lua_Number)time);
    return 1;
}
#endif

LUALIB_API int luaopen_benchmarklib(lua_State *L) {
    luaL_Reg libs[] = {
        ENTRY(cpu_clock),
        ENTRY(wall_clock),
        { NULL, NULL }
    };

#if LUA_VERSION_NUM >= 502 // lua 5.2+
    luaL_newlib(L, libs);
#else
    lua_createtable(L, 0, sizeof(libs)/sizeof(libs[0]));
    luaL_register(L, NULL, libs);
#endif
    return 1;
}
/*
 * CC -shared -o benchmarklib.so -fPIC -O2 benchmarklib.c -I/usr/include/LUA_VERSION 
 * -Wall -Wextra -lLUA_VERSION
 */
