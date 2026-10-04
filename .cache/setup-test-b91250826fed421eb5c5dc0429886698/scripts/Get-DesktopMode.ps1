#requires -Version 5.1
# Read physical pixels, independently of Windows' UI/DPI scaling. This API only
# queries the primary display; it never changes a Windows display setting.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not ('Stilbomber.DesktopDisplay' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace Stilbomber
{
    // Relevant fields of the fixed-size Win32 DEVMODEW structure.
    [StructLayout(LayoutKind.Explicit, Size = 220, CharSet = CharSet.Unicode)]
    public struct DesktopMode
    {
        [FieldOffset(68)] public ushort Size;
        [FieldOffset(168)] public uint BitsPerPixel;
        [FieldOffset(172)] public uint Width;
        [FieldOffset(176)] public uint Height;
        [FieldOffset(184)] public uint RefreshRate;
    }

    public static class DesktopDisplay
    {
        [DllImport("user32.dll", CharSet = CharSet.Unicode, ExactSpelling = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool EnumDisplaySettingsW(
            string deviceName, int modeNumber, ref DesktopMode mode);

        public static DesktopMode GetCurrent()
        {
            var mode = new DesktopMode();
            mode.Size = (ushort)Marshal.SizeOf(typeof(DesktopMode));
            if (!EnumDisplaySettingsW(null, -1, ref mode) || mode.Width == 0 || mode.Height == 0)
                throw new InvalidOperationException("Cannot read the current desktop display mode.");
            return mode;
        }
    }
}
'@
}

[Stilbomber.DesktopDisplay]::GetCurrent()
