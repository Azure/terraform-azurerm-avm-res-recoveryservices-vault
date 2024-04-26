
$exampleFolders = Get-ChildItem -Directory

foreach ($folder in $exampleFolders) {
    <# $folder is the current item #>
    write-host "`n################################################`n"
    write-host "Running example $($folder.FullName)" -ForegroundColor green  -BackgroundColor Blue
    
    write-host "`n Terraform init on $($folder.FullName)" -ForegroundColor green -BackgroundColor Blue
    terraform -chdir="$folder" init -upgrade
    
    Start-Sleep 10
    
    write-host "`n Terraform plan on $($folder.FullName)" -ForegroundColor green  -BackgroundColor Blue
    terraform -chdir="$folder" plan -out="$($folder.Name)" -parallelism=60
    
    Start-Sleep 10
    
    write-host "`n Terraform apply on $($folder.FullName)" -ForegroundColor green  -BackgroundColor Blue
    terraform -chdir="$folder" apply -auto-approve -parallelism=60 "$($folder.Name)"
    
    Start-Sleep 10
    
    write-host "`n Terraform destroy on $($folder.FullName)" -ForegroundColor red -BackgroundColor Blue
    terraform -chdir="$folder" plan -out="$($folder.Name)-destroy" -parallelism=60 -destroy
    terraform -chdir="$folder" apply -auto-approve -parallelism=60 "$($folder.Name)-destroy"

}