#if defined(__APPLE__)
#import <Cocoa/Cocoa.h>
#include <core/icon.hpp>

Tray::Icon::Icon(const std::string &path)
{
    NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:nsPath];

    if (image) {
        // Resize to standard status bar icon size (22x22 points for @1x)
        [image setSize:NSMakeSize(22.0, 22.0)];
        nsImage = (__bridge_retained void*)image;
    } else {
        // If file loading fails, try loading from system resources
        image = [NSImage imageNamed:nsPath];
        if (image) {
            image = [image copy];  // Make a copy to own it
            [image setSize:NSMakeSize(22.0, 22.0)];
            nsImage = (__bridge_retained void*)image;
        } else {
            nsImage = nullptr;
        }
    }
}

Tray::Icon::Icon(const char *path) : Icon(std::string(path)) {}

Tray::Icon::operator void*()
{
    return nsImage;
}

Tray::Icon::~Icon()
{
    if (nsImage) {
        CFRelease(nsImage);
    }
}

#endif
