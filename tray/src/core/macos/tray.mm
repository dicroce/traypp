#if defined(__APPLE__)
#import <Cocoa/Cocoa.h>
#include <core/macos/tray.hpp>
#include <stdexcept>

#include <components/button.hpp>
#include <components/imagebutton.hpp>
#include <components/label.hpp>
#include <components/separator.hpp>
#include <components/submenu.hpp>
#include <components/syncedtoggle.hpp>
#include <components/toggle.hpp>

// Objective-C delegate class to bridge menu item clicks to C++
@interface TrayDelegate : NSObject
{
    @public
    Tray::Tray *tray;
}
- (void)menuItemClicked:(id)sender;
@end

@implementation TrayDelegate
- (void)menuItemClicked:(id)sender
{
    NSMenuItem *menuItem = (NSMenuItem *)sender;
    NSValue *value = (NSValue *)menuItem.representedObject;
    Tray::TrayEntry *item = (Tray::TrayEntry *)[value pointerValue];

    if (auto *button = dynamic_cast<Tray::Button *>(item); button)
    {
        button->clicked();
    }
    else if (auto *toggle = dynamic_cast<Tray::Toggle *>(item); toggle)
    {
        toggle->onToggled();
        if (tray)
        {
            tray->update();
        }
    }
    else if (auto *syncedToggle = dynamic_cast<Tray::SyncedToggle *>(item); syncedToggle)
    {
        syncedToggle->onToggled();
        if (tray)
        {
            tray->update();
        }
    }
}
@end

Tray::Tray::Tray(std::string identifier, Icon icon) : BaseTray(std::move(identifier), icon)
{
    @autoreleasepool {
        // Initialize NSApplication if not already done
        NSApp = [NSApplication sharedApplication];

        // Set activation policy to accessory so app doesn't appear in dock
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

        // Finish launching if not already done
        if (![NSApp isRunning]) {
            [NSApp finishLaunching];
        }

        // Create status bar item
        statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
        if (!statusItem)
        {
            throw std::runtime_error("Failed to create status item");
        }

        // Set the icon
        NSImage *nsIcon = (__bridge NSImage *)static_cast<void*>(this->icon);
        if (nsIcon && [nsIcon isKindOfClass:[NSImage class]])
        {
            // Set the icon as a template so it adapts to light/dark mode
            [nsIcon setTemplate:YES];
            statusItem.button.image = nsIcon;
        } else {
            // Even without an icon, set a visible title so the item appears
            statusItem.button.title = @"⚫";
        }

        // Create menu
        menu = [[NSMenu alloc] init];
        menu.autoenablesItems = NO;  // We'll manage enabled state manually

        // Create delegate for callbacks
        delegate = [[TrayDelegate alloc] init];
        delegate->tray = this;
    }
}

Tray::Tray::~Tray()
{
    @autoreleasepool {
        if (statusItem)
        {
            [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
            [statusItem release];
            statusItem = nullptr;
        }

        if (menu)
        {
            [menu release];
            menu = nullptr;
        }

        if (delegate)
        {
            [delegate release];
            delegate = nullptr;
        }
    }
}

void Tray::Tray::exit()
{
    @autoreleasepool {
        if (statusItem)
        {
            [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
            [statusItem release];
            statusItem = nullptr;
        }

        [NSApp stop:nil];

        // Post a dummy event to wake up the event loop
        NSEvent *event = [NSEvent otherEventWithType:NSEventTypeApplicationDefined
                                            location:NSMakePoint(0, 0)
                                       modifierFlags:0
                                           timestamp:0
                                        windowNumber:0
                                             context:nil
                                             subtype:0
                                               data1:0
                                               data2:0];
        [NSApp postEvent:event atStart:YES];
    }
}

void Tray::Tray::update()
{
    @autoreleasepool {
        // Don't update if not fully initialized
        if (!statusItem || !menu || !delegate) {
            return;
        }

        // Clear existing menu items
        [menu removeAllItems];

        // Reconstruct menu items directly into the existing menu
        constructIntoMenu(menu, entries, this);

        // Set the menu on the status item
        statusItem.menu = menu;
    }
}

// Helper to construct menu items into an existing menu
void Tray::Tray::constructIntoMenu(NSMenu *nsMenu, const std::vector<std::shared_ptr<TrayEntry>> &entries, Tray *parent)
{
    @autoreleasepool {
        for (const auto &entry : entries)
        {
            auto *item = entry.get();
            NSMenuItem *nsItem = nil;

            if (auto *toggle = dynamic_cast<Toggle *>(item); toggle)
            {
                nsItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithUTF8String:toggle->getText().c_str()]
                                                    action:@selector(menuItemClicked:)
                                             keyEquivalent:@""];
                nsItem.target = parent->delegate;
                nsItem.state = toggle->isToggled() ? NSControlStateValueOn : NSControlStateValueOff;
                nsItem.representedObject = [NSValue valueWithPointer:item];
            }
            else if (auto *syncedToggle = dynamic_cast<SyncedToggle *>(item); syncedToggle)
            {
                nsItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithUTF8String:syncedToggle->getText().c_str()]
                                                    action:@selector(menuItemClicked:)
                                             keyEquivalent:@""];
                nsItem.target = parent->delegate;
                nsItem.state = syncedToggle->isToggled() ? NSControlStateValueOn : NSControlStateValueOff;
                nsItem.representedObject = [NSValue valueWithPointer:item];
            }
            else if (auto *submenu = dynamic_cast<Submenu *>(item); submenu)
            {
                nsItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithUTF8String:submenu->getText().c_str()]
                                                    action:nil
                                             keyEquivalent:@""];
                NSMenu *subMenu = construct(submenu->getEntries(), parent);
                nsItem.submenu = subMenu;
            }
            else if (auto *imageButton = dynamic_cast<ImageButton *>(item); imageButton)
            {
                nsItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithUTF8String:imageButton->getText().c_str()]
                                                    action:@selector(menuItemClicked:)
                                             keyEquivalent:@""];
                nsItem.target = parent->delegate;
                nsItem.representedObject = [NSValue valueWithPointer:item];

                NSImage *nsImage = (__bridge NSImage *)static_cast<void*>(imageButton->getImage());
                if (nsImage)
                {
                    nsItem.image = nsImage;
                }
            }
            else if (dynamic_cast<Button *>(item))
            {
                const char *text = item->getText().c_str();
                NSString *title = text ? [NSString stringWithUTF8String:text] : @"";
                nsItem = [[NSMenuItem alloc] initWithTitle:title
                                                    action:@selector(menuItemClicked:)
                                             keyEquivalent:@""];
                nsItem.target = parent->delegate;
                nsItem.representedObject = [NSValue valueWithPointer:item];
            }
            else if (dynamic_cast<Label *>(item))
            {
                nsItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithUTF8String:item->getText().c_str()]
                                                    action:nil
                                             keyEquivalent:@""];
                nsItem.enabled = NO;
            }
            else if (dynamic_cast<Separator *>(item))
            {
                nsItem = [NSMenuItem separatorItem];
            }

            // Handle disabled state (unless it's already a Label which is always disabled)
            if (nsItem && !dynamic_cast<Label *>(item))
            {
                nsItem.enabled = !item->isDisabled();
            }

            if (nsItem)
            {
                [nsMenu addItem:nsItem];
            }
        }
    }
}

// Construct a new menu (used for submenus)
NSMenu *Tray::Tray::construct(const std::vector<std::shared_ptr<TrayEntry>> &entries, Tray *parent)
{
    @autoreleasepool {
        NSMenu *nsMenu = [[NSMenu alloc] init];
        nsMenu.autoenablesItems = NO;
        constructIntoMenu(nsMenu, entries, parent);
        return nsMenu;
    }
}

void Tray::Tray::run()
{
    @autoreleasepool {
        // Build menu items into the existing menu
        constructIntoMenu(menu, entries, this);
        statusItem.menu = menu;

        // Run the application event loop
        [NSApp run];
    }
}

void Tray::Tray::pump()
{
    @autoreleasepool {
        // Process one event from the queue
        NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                            untilDate:[NSDate distantPast]
                                               inMode:NSDefaultRunLoopMode
                                              dequeue:YES];
        if (event)
        {
            [NSApp sendEvent:event];
            [NSApp updateWindows];
        }
    }
}

#endif
