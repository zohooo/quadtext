
// modified from https://gist.github.com/pkulchenko/73fb5c32f20d90ece1db

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <windows.h>

int main (int argc, char *argv[])
{
    char buffer[MAX_PATH], *file;

    if (!GetFullPathName(argv[0], MAX_PATH, buffer, &file)) {
        MessageBox(NULL,
            TEXT("Couldn't find the correct working directory"),
            TEXT("Failed to start editor"),
            MB_OK|MB_ICONERROR);
        return 1;
    }
    // finish the buffer string; don't need the appname
    if (file != NULL) *file = '\0';

    char *arg = GetCommandLine();
    int l = strlen(argv[0]);

    // since the name can be quoted in arg, but may not be in argv,
    // account for those quotes
    if (arg == strstr(arg, argv[0])) {
        arg += l;
    } else if (arg[0] == '"') {
        if (argc > 2) arg += l + 2; else arg = "";
    } else {
        MessageBox(NULL,
            TEXT("Couldn't get command line arguments"),
            TEXT("Failed to start editor"),
        MB_OK|MB_ICONERROR);
        return 1;
    }

    char *lua = "binary\\lua.exe source\\main.lua ";
    char *cl = (char*) malloc(strlen(lua) + strlen(arg));
    strcpy(cl, lua);
    strcat(cl, arg);

    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    ZeroMemory(&si, sizeof(STARTUPINFO));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(PROCESS_INFORMATION));

    // Start the child process.
    if(!CreateProcess(NULL, cl, NULL, NULL, FALSE,
        CREATE_NO_WINDOW, NULL, buffer, &si, &pi)) {
            MessageBox(NULL,
                TEXT("Couldn't launch Lua interpreter"),
                TEXT("Failed to start editor"),
            MB_OK|MB_ICONERROR);
            return 1;
    }

    // Wait until child process exits.
    WaitForSingleObject(pi.hProcess, INFINITE);

    free(cl);

    // Close process and thread handles.
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return 0;
}
