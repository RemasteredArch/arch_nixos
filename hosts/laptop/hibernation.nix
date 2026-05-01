# Configures sleeping (suspending to memory) and hibernation (suspending to disk).
#
# Based off of <https://nixos.wiki/wiki/Hibernation>.
{
    services.logind.settings.Login = {
        LidSwitch = "suspend-then-hibernate";
        PowerKey = "hibernate";
        PowerKeyLongPress = "poweroff";
    };

    # Probably irrelevant if `MemorySleepMode` is configured in systemd.
    boot.kernelParams = [ "mem_sleep_default=deep" ];
    # Define time delay for hibernation.
    #
    # See <https://www.mankier.com/5/systemd-sleep.conf#Options>.
    systemd.sleep.settings = {
        # Hibernate after being asleep for thirty minutes (or after dipping below 5% battery).
        HibernateDelaySec = "30m";

        # Initially suspend to memory.
        SuspendState = "mem";

        # Actually suspend-to-RAM during memory suspend instead of idling.
        #
        # <https://docs.kernel.org/admin-guide/pm/sleep-states.html#basic-sysfs-interfaces-for-system-suspend-and-hibernation>
        MemorySleepMode = "deep";
    };
}
