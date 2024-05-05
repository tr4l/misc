Class MultiPassExport
{
    [String]$category
    [String]$software
    [String]$version
    [hashtable]$files
    [hashtable]$data
    MultiPassExport (){
        $this.data = [ordered]@{}
        $this.files = [ordered]@{}
    }
}
