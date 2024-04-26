
$exampleFolders = Get-ChildItem -Directory

foreach ($folder in $exampleFolders) {
    <# $folder is the current item #>
    Write-Output "Running example $($folder.FullName)"
    
    Write-Output "`n Terraform init on $($folder.FullName)"
    terraform -chdir="$folder" init -upgrade
    
    Start-Sleep 10
    
    Write-Output "`n Terraform init on $($folder.FullName)"
    terraform -chdir="$folder" plan -parallelism=60
    
    Start-Sleep 10
    
    Write-Output "`n Terraform init on $($folder.FullName)"
    terraform -chdir="$folder" apply -parallelism=60 #-target

}