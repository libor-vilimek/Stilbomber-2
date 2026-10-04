param([int] $GameProcessId, [switch] $IncludeChildren)
$ErrorActionPreference = 'Stop'
if (-not ('StilbomberDiagnostic.Windows' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
namespace StilbomberDiagnostic {
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left,Top,Right,Bottom; }
    public class Entry {
        public long Handle,Owner;
        public string Class,Title;
        public bool Visible;
        public Rect Window,Client;
        public uint Dpi,Style,ExStyle;
    }
    public static class Windows {
        private delegate bool Callback(IntPtr hwnd, IntPtr arg);
        [DllImport("user32.dll")] private static extern bool EnumWindows(Callback callback, IntPtr arg);
        [DllImport("user32.dll")] private static extern bool EnumChildWindows(IntPtr parent, Callback callback, IntPtr arg);
        [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
        [DllImport("user32.dll",CharSet=CharSet.Unicode)] private static extern int GetClassName(IntPtr hwnd,StringBuilder name,int size);
        [DllImport("user32.dll",CharSet=CharSet.Unicode)] private static extern int GetWindowText(IntPtr hwnd,StringBuilder text,int size);
        [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr hwnd);
        [DllImport("user32.dll")] private static extern bool GetWindowRect(IntPtr hwnd,out Rect r);
        [DllImport("user32.dll")] private static extern bool GetClientRect(IntPtr hwnd,out Rect r);
        [DllImport("user32.dll")] private static extern int GetWindowLong(IntPtr hwnd,int index);
        [DllImport("user32.dll")] private static extern uint GetDpiForWindow(IntPtr hwnd);
        [DllImport("user32.dll")] private static extern IntPtr GetWindow(IntPtr hwnd,uint command);
        [DllImport("user32.dll")] private static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
        public static Entry[] Inspect(uint processId, bool includeChildren) {
            var previous = SetThreadDpiAwarenessContext(new IntPtr(-4));
            try {
                var entries = new List<Entry>();
                var seen = new HashSet<long>();
                Callback inspect = delegate(IntPtr hwnd, IntPtr arg) {
                    uint pid; GetWindowThreadProcessId(hwnd,out pid);
                    if (pid != processId || !seen.Add(hwnd.ToInt64())) return true;
                    var c = new StringBuilder(256); var t = new StringBuilder(512);
                    GetClassName(hwnd,c,c.Capacity); GetWindowText(hwnd,t,t.Capacity);
                    Rect r,client; GetWindowRect(hwnd,out r); GetClientRect(hwnd,out client);
                    entries.Add(new Entry { Handle=hwnd.ToInt64(),Owner=GetWindow(hwnd,4).ToInt64(),Class=c.ToString(),Title=t.ToString(),
                        Visible=IsWindowVisible(hwnd),Window=r,Client=client,Dpi=GetDpiForWindow(hwnd),
                        Style=unchecked((uint)GetWindowLong(hwnd,-16)),ExStyle=unchecked((uint)GetWindowLong(hwnd,-20)) });
                    return true;
                };
                EnumWindows(delegate(IntPtr hwnd, IntPtr arg) {
                    uint pid; GetWindowThreadProcessId(hwnd,out pid);
                    if (pid != processId) return true;
                    inspect(hwnd,arg);
                    if (includeChildren) EnumChildWindows(hwnd,inspect,arg);
                    return true;
                },IntPtr.Zero);
                return entries.ToArray();
            } finally { if (previous != IntPtr.Zero) SetThreadDpiAwarenessContext(previous); }
        }
    }
}
'@
}
if (-not $GameProcessId) {
    $game = Get-Process -Name stilbomber2v103 -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -eq 'C:\src\stilbomber-reloaded\game\stilbomber2v103.exe' } |
        Select-Object -First 1
    if (-not $game) { return }
    $GameProcessId = $game.Id
}
[StilbomberDiagnostic.Windows]::Inspect($GameProcessId, [bool]$IncludeChildren)
