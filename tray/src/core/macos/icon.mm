#if defined(__APPLE__)
#import <Cocoa/Cocoa.h>
#include <core/icon.hpp>

Tray::Icon::Icon(const std::string &path)
{
    NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
    NSImage *image = nil;

    // If path is not empty, try to load it
    if (!path.empty()) {
        // Try loading from file
        image = [[NSImage alloc] initWithContentsOfFile:nsPath];

        if (!image) {
            // If file loading fails, try loading from system resources
            image = [NSImage imageNamed:nsPath];
            if (image) {
                image = [image copy];  // Make a copy to own it
            }
        }
    }

    // If we have an image, set it up
    if (image) {
        [image setSize:NSMakeSize(18.0, 18.0)];
        nsImage = (__bridge void*)image;
    } else {
        // Create a simple default icon using a more reliable approach
        NSImage *defaultIcon = [[NSImage alloc] initWithSize:NSMakeSize(18.0, 18.0)];

        // Use a block-based drawing approach which is more reliable
        [defaultIcon lockFocus];
        // Clear with transparency first
        [[NSColor clearColor] setFill];
        NSRectFill(NSMakeRect(0, 0, 18, 18));
        // Draw a small filled circle
        [[NSColor blackColor] setFill];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(5, 5, 8, 8)] fill];
        [defaultIcon unlockFocus];

        // defaultIcon is already retained by alloc, just bridge it
        nsImage = (__bridge void*)defaultIcon;
    }
}

Tray::Icon::Icon(const char *path) : Icon(std::string(path)) {}

Tray::Icon::Icon(const Icon &other) : nsImage(other.nsImage)
{
    if (nsImage) {
        CFRetain(nsImage);
    }
}

Tray::Icon &Tray::Icon::operator=(const Icon &other)
{
    if (this != &other) {
        if (nsImage) {
            CFRelease(nsImage);
        }
        nsImage = other.nsImage;
        if (nsImage) {
            CFRetain(nsImage);
        }
    }
    return *this;
}

Tray::Icon::Icon(Icon &&other) noexcept : nsImage(other.nsImage)
{
    other.nsImage = nullptr;
}

Tray::Icon &Tray::Icon::operator=(Icon &&other) noexcept
{
    if (this != &other) {
        if (nsImage) {
            CFRelease(nsImage);
        }
        nsImage = other.nsImage;
        other.nsImage = nullptr;
    }
    return *this;
}

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
