#pragma once
#if defined(__APPLE__)
#include <core/traybase.hpp>

// Forward declarations to avoid Objective-C in header
#ifdef __OBJC__
@class NSStatusItem;
@class NSMenu;
@class NSMenuItem;
@class TrayDelegate;
#else
typedef void NSStatusItem;
typedef void NSMenu;
typedef void NSMenuItem;
typedef void TrayDelegate;
#endif

namespace Tray
{
    class Tray : public BaseTray
    {
        NSStatusItem *statusItem;
        NSMenu *menu;
        TrayDelegate *delegate;

        static NSMenu *construct(const std::vector<std::shared_ptr<TrayEntry>> &, Tray *parent);
        static void menuItemClicked(void *context);

      public:
        ~Tray();
        Tray(std::string identifier, Icon icon);
        template <typename... T> Tray(std::string identifier, Icon icon, const T &...entries) : Tray(identifier, icon)
        {
            addEntries(entries...);
        }

        void run() override;
        void exit() override;
        void update() override;
        void pump() override;
    };
} // namespace Tray
#endif
