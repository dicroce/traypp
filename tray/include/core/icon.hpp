#pragma once
#include <string>
#if defined(_WIN32)
#include <Windows.h>
#endif

namespace Tray
{
#if defined(__linux__)
    class Icon
    {
        std::string iconPath;

      public:
        Icon(std::string path);
        Icon(const char *path);
        operator const char *();
    };
#elif defined(_WIN32)
    class Icon
    {
        HICON hIcon;

      public:
        Icon(HICON icon);
        Icon(WORD resource);
        Icon(const char *path);
        Icon(const std::string &path);

        operator HICON();
    };
#elif defined(__APPLE__)
    class Icon
    {
        void *nsImage;  // NSImage*

      public:
        ~Icon();
        Icon(const char *path);
        Icon(const std::string &path);

        operator void*();
    };
#endif
} // namespace Tray