using System.Collections.Generic;
using System;
using System.Text;

namespace PowWow
{
    class PowFun
    {
        public static Dictionary<string, string> Funcs;
        private static char dKey;
        public static void id()
        {
            Funcs = new Dictionary<string, string>();
            //Don't change the dollar sign line
            //$$$
        }
        public static string ds(string enc)
        {
            byte[] decoded = Convert.FromBase64String(enc);

            for (int i = 0; i < decoded.Length; i++)
            {
                decoded[i] ^= (byte)PowFun.dKey;
            }

            return Encoding.UTF8.GetString(decoded);
        }

        public static string es(string dec)
        {
            //Lop off PS1 or other file extension from scriptname
            Byte[] moduleName = Encoding.UTF8.GetBytes(dec);
            Byte[] outModuleName = new Byte[moduleName.Length];

            for (int i = 0; i < moduleName.Length; i++)
            {
                outModuleName[i] = (byte)(moduleName[i] ^ PowFun.dKey);
            }
            return Convert.ToBase64String(outModuleName);
        }

    }
}
