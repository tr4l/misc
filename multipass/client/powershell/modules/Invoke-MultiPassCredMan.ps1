# Got from and slight change https://github.com/EmpireProject/Empire/blob/master/data/module_source/credentials/dumpCredStore.ps1 
#region Pinvoke
#region Inline C#
[String] $PsCredmanUtils = @"
using System;
using System.Runtime.InteropServices;

namespace PsUtils
{
    public class CredMan
    {
        #region Imports
        // DllImport derives from System.Runtime.InteropServices

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredEnumerateW", CharSet = CharSet.Unicode)]
        private static extern bool CredEnumerateW([In] string Filter, [In] int Flags, out int Count, out IntPtr CredentialPtr);

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredFree")]
        private static extern void CredFree([In] IntPtr cred);


        #endregion

        #region Fields
        public enum CRED_FLAGS : uint
        {
            NONE = 0x0,
            PROMPT_NOW = 0x2,
            USERNAME_TARGET = 0x4
        }

        public enum CRED_ERRORS : uint
        {
            ERROR_SUCCESS = 0x0,
            ERROR_INVALID_PARAMETER = 0x80070057,
            ERROR_INVALID_FLAGS = 0x800703EC,
            ERROR_NOT_FOUND = 0x80070490,
            ERROR_NO_SUCH_LOGON_SESSION = 0x80070520,
            ERROR_BAD_USERNAME = 0x8007089A
        }

        public enum CRED_PERSIST : uint
        {
            SESSION = 1,
            LOCAL_MACHINE = 2,
            ENTERPRISE = 3
        }

        public enum CRED_TYPE : uint
        {
            GENERIC = 1,
            DOMAIN_PASSWORD = 2,
            DOMAIN_CERTIFICATE = 3,
            DOMAIN_VISIBLE_PASSWORD = 4,
            GENERIC_CERTIFICATE = 5,
            DOMAIN_EXTENDED = 6,
            MAXIMUM = 7,      // Maximum supported cred type
            MAXIMUM_EX = (MAXIMUM + 1000),  // Allow new applications to run on old OSes
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct Credential
        {
            public CRED_FLAGS Flags;
            public CRED_TYPE Type;
            public string TargetName;
            public string Comment;
            public DateTime LastWritten;
            public UInt32 CredentialBlobSize;
            public string CredentialBlob;
            public CRED_PERSIST Persist;
            public UInt32 AttributeCount;
            public IntPtr Attributes;
            public string TargetAlias;
            public string UserName;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct NativeCredential
        {
            public CRED_FLAGS Flags;
            public CRED_TYPE Type;
            public IntPtr TargetName;
            public IntPtr Comment;
            public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
            public UInt32 CredentialBlobSize;
            public IntPtr CredentialBlob;
            public UInt32 Persist;
            public UInt32 AttributeCount;
            public IntPtr Attributes;
            public IntPtr TargetAlias;
            public IntPtr UserName;
        }
        #endregion

        #region Child Class
        private class CriticalCredentialHandle : Microsoft.Win32.SafeHandles.CriticalHandleZeroOrMinusOneIsInvalid
        {
            public CriticalCredentialHandle(IntPtr preexistingHandle)
            {
                SetHandle(preexistingHandle);
            }

            private Credential XlateNativeCred(IntPtr pCred)
            {
                NativeCredential ncred = (NativeCredential)Marshal.PtrToStructure(pCred, typeof(NativeCredential));
                Credential cred = new Credential();
                cred.Type = ncred.Type;
                cred.Flags = ncred.Flags;
                cred.Persist = (CRED_PERSIST)ncred.Persist;

                long LastWritten = ncred.LastWritten.dwHighDateTime;
                LastWritten = (LastWritten << 32) + ncred.LastWritten.dwLowDateTime;
                cred.LastWritten = DateTime.FromFileTime(LastWritten);

                cred.UserName = Marshal.PtrToStringUni(ncred.UserName);
                cred.TargetName = Marshal.PtrToStringUni(ncred.TargetName);
                cred.TargetAlias = Marshal.PtrToStringUni(ncred.TargetAlias);
                cred.Comment = Marshal.PtrToStringUni(ncred.Comment);
                cred.CredentialBlobSize = ncred.CredentialBlobSize;
                if (0 < ncred.CredentialBlobSize)
                {
                    cred.CredentialBlob = Marshal.PtrToStringUni(ncred.CredentialBlob, (int)ncred.CredentialBlobSize / 2);
                }
                return cred;
            }

            public Credential[] GetCredentials(int count)
            {
                if (IsInvalid)
                {
                    throw new InvalidOperationException("Invalid CriticalHandle!");
                }
                Credential[] Credentials = new Credential[count];
                IntPtr pTemp = IntPtr.Zero;
                for (int inx = 0; inx < count; inx++)
                {
                    pTemp = Marshal.ReadIntPtr(handle, inx * IntPtr.Size);
                    Credential cred = XlateNativeCred(pTemp);
                    Credentials[inx] = cred;
                }
                return Credentials;
            }

            override protected bool ReleaseHandle()
            {
                if (IsInvalid)
                {
                    return false;
                }
                CredFree(handle);
                SetHandleAsInvalid();
                return true;
            }
        }
        #endregion

        #region Custom API
        public static int CredEnum(string Filter, out Credential[] Credentials)
        {
            int count = 0;
            int Flags = 0x0;
            if (string.IsNullOrEmpty(Filter) ||
                "*" == Filter)
            {
                Filter = null;
                if (6 <= Environment.OSVersion.Version.Major)
                {
                    Flags = 0x1; //CRED_ENUMERATE_ALL_CREDENTIALS; only valid is OS >= Vista
                }
            }
            IntPtr pCredentials = IntPtr.Zero;
            if (!CredEnumerateW(Filter, Flags, out count, out pCredentials))
            {
                Credentials = null;
                return Marshal.GetHRForLastWin32Error(); 
            }
            CriticalCredentialHandle CredHandle = new CriticalCredentialHandle(pCredentials);
            Credentials = CredHandle.GetCredentials(count);
            return 0;
        }
        #endregion

        private static bool CheckError(string TestName, CRED_ERRORS Rtn)
        {
            switch(Rtn)
            {
                case CRED_ERRORS.ERROR_SUCCESS:
                    Console.WriteLine(string.Format("'{0}' worked", TestName));
                    return true;
                case CRED_ERRORS.ERROR_INVALID_FLAGS:
                case CRED_ERRORS.ERROR_INVALID_PARAMETER:
                case CRED_ERRORS.ERROR_NO_SUCH_LOGON_SESSION:
                case CRED_ERRORS.ERROR_NOT_FOUND:
                case CRED_ERRORS.ERROR_BAD_USERNAME:
                    Console.WriteLine(string.Format("'{0}' failed; {1}.", TestName, Rtn));
                    break;
                default:
                    Console.WriteLine(string.Format("'{0}' failed; 0x{1}.", TestName, Rtn.ToString("X")));
                    break;
            }
            return false;
        }

    }
}
"@
#endregion

$PsCredMan = $null
try
{
	$PsCredMan = [PsUtils.CredMan]
}
catch
{
	#only remove the error we generate
	$Error.RemoveAt($Error.Count-1)
}
if($null -eq $PsCredMan)
{
	Add-Type $PsCredmanUtils
}
#endregion

function Invoke-MultiPassCredMan {
    $export = New-Object MultiPassExport
    $export.category = "Windows"
    $export.software = "credman"
	$enc = [system.Text.Encoding]::UTF8 # Not sure I should use UTF-8, but what instead?

	[PsUtils.CredMan+Credential[]] $Creds = [Array]::CreateInstance([PsUtils.CredMan+Credential], 0)
	[PsUtils.CredMan]::CredEnum([String]::Empty, [Ref]$Creds)
	foreach($Cred in $Creds)
	{

	  $jCred = [ordered]@{}
	  $jCred["UserName"] = $Cred.UserName
	  $jCred["Flags"] = $Cred.Flags
	  $jCred["Type"] = $Cred.Type
	  $jCred["TargetName"] = $Cred.TargetName
	  $jCred["Comment"] = $Cred.Comment
	  $jCred["LastWritten"] = $Cred.LastWritten
      $jCred["CredentialBlobSize"] = $Cred.CredentialBlobSize
      if ($Cred.CredentialBlobSize -ne 0){
        $jCred["CredentialBlob"] = [System.Convert]::ToBase64String($enc.GetBytes($Cred.CredentialBlob))
      }
	  $jCred["Persist"] = $Cred.Persist
	  $jCred["AttributeCount"] = $Cred.AttributeCount
	  $jCred["Attributes"] = $Cred.Attributes
      $jCred["TargetAlias"] = $Cred.TargetAlias
      $export.data["creds:"+$Cred.TargetName] = $jCred | ConvertTo-Json
	}
    return $export
}