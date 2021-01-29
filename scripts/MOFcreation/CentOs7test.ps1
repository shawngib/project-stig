Configuration ExampleConfiguration
{
     Import-DscResource -Module nx

     Node  "linuxhost.contoso.com"
     {
         nxFile ExampleFile
         {
             DestinationPath = "/tmp/example"
             Contents = "hello world `n"
             Ensure = "Present"
             Type = "File"
         }
     }
}

ExampleConfiguration