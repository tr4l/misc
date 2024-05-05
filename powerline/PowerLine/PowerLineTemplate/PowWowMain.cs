using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;

namespace PowWow
{
    class PowWowMain
    {

        static void Main(string[] args)
        {
            Magic.EntryPoint(args);
        }
    }

   
    public class Magic
    {
        public static void EntryPoint(string[] args)
        {
            if (args.Length == 0)
            {
                return;
            }

            PowFun.id();
            ef(args);
        }

        public static void ef(string[] args)
        {
            string script = PowFun.es(args[0]);
            if (!PowFun.Funcs.ContainsKey(script)){
                return;
            }
            string command = PowFun.ds(PowFun.Funcs[script]);

            if (args.Length > 1)
            {
                string parameters = "\n" + args[1] + "\n";
                command += parameters;
            }

            //Runs powershell stuff
            
            PowWhost powWhost = new PowWhost();
            Runspace rspace = RunspaceFactory.CreateRunspace(powWhost);
            rspace.Open();
            Pipeline pipeline = rspace.CreatePipeline();
            pipeline.Commands.AddScript(command);
            //pipeline.Commands[0].MergeMyResults(PipelineResultTypes.Error, PipelineResultTypes.Output);
            //pipeline.Commands.Add("Out-Default");
            Collection<PSObject> commandResults = pipeline.Invoke();

            List<string> outp;
            outp = ((PowWhostUi)powWhost.UI).Output;
            int idx = 0;
            while (idx < outp.Count)
            {
                Console.Write(outp[idx]);
                idx++;
            }
        }
    }

}
