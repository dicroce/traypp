#if defined(__APPLE__)
#import <Cocoa/Cocoa.h>
#include <core/image.hpp>

Tray::Image::Image(void *image) : nsImage(image) {}

Tray::Image::Image(const char *path) : Image(std::string(path)) {}

Tray::Image::Image(const std::string &path)
{
    NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:nsPath];

    if (image) {
        // Resize to standard menu item icon size (16x16 points)
        [image setSize:NSMakeSize(16.0, 16.0)];
        nsImage = (__bridge_retained void*)image;
    } else {
        // Try loading from system resources
        image = [NSImage imageNamed:nsPath];
        if (image) {
            image = [image copy];  // Make a copy to own it
            [image setSize:NSMakeSize(16.0, 16.0)];
            nsImage = (__bridge_retained void*)image;
        } else {
            nsImage = nullptr;
        }
    }
}

Tray::Image::operator void*()
{
    return nsImage;
}

Tray::Image::~Image()
{
    if (nsImage) {
        CFRelease(nsImage);
    }
}

#endif
