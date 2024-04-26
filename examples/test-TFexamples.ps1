
$exampleFolders = Get-ChildItem -Directory

foreach ($folder in $exampleFolders) {
    <# $folder is the current item #>
    Write-Output "Running example $($folder.FullName)"
    
    Write-Output "`n Terraform init on $($folder.FullName)"
    terraform -chdir="$folder" init -upgrade
    
    Start-Sleep 10
    
    Write-Output "`n Terraform init on $($folder.FullName)"
    terraform -chdir="$folder" plan -out="$($folder.Name)" -parallelism=60
    
    Start-Sleep 10
    
    Write-Output "`n Terraform init on $($folder.FullName)"
    terraform -chdir="$folder" apply -auto-approve -parallelism=60 "$($folder.Name)"
    
    Start-Sleep 10
    
    Write-Output "`n Terraform init on $($folder.FullName)"
    terraform -chdir="$folder" plan -out="$($folder.Name)-destroy" -parallelism=60 -destroy
    terraform -chdir="$folder" destroy -auto-approve -parallelism=60 "$($folder.Name)-destroy"

}