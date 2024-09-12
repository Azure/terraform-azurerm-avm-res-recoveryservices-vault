
$sub_id = "d200e3b2-c0dc-4076-bd30-4ccccf05ffeb"
$exampleFolders = Get-ChildItem -Directory

foreach ($folder in $exampleFolders) {
    <# $folder is the current item #>
    write-host "`n################################################`n"
    write-host "Running example $($folder.FullName)" -ForegroundColor green  -BackgroundColor Blue
    
    write-host "`n Terraform init on $($folder.FullName)" -ForegroundColor green -BackgroundColor Blue
    terraform -chdir="$folder" init -upgrade
    
    Start-Sleep 10
    
    write-host "`n Terraform plan on $($folder.FullName)" -ForegroundColor green  -BackgroundColor Blue
    terraform -chdir="$folder" plan -var="subscription_id=$sub_id" -out="$($folder.Name).plan" -parallelism=60
    
    Start-Sleep 10
    
    write-host "`n Terraform apply on $($folder.FullName)" -ForegroundColor green  -BackgroundColor Blue
    terraform -chdir="$folder" apply -auto-approve -parallelism=60 "$($folder.Name).plan"
    
    Start-Sleep 10
    
    write-host "`n Terraform destroy on $($folder.FullName)" -ForegroundColor red -BackgroundColor Blue
    terraform -chdir="$folder" plan -var="subscription_id=$sub_id" -out="$($folder.Name)-destroy.plan" -parallelism=60 -destroy
    terraform -chdir="$folder" apply -auto-approve -parallelism=60 "$($folder.Name)-destroy.plan"

    Get-ChildItem -Filter *.plan -Recurse | Remove-Item -Force

}

<# 
# Running all pre-commit checks
# `pre-commit` runs depsensure fmt fumpt autofix docs
# `pr-check` runs fmtcheck tfvalidatecheck lint unit-test

## Windows

write-host "`n################################################`n"
write-host "Running docscheck" -ForegroundColor green  -BackgroundColor Blue
./avm docscheck

write-host "`n################################################`n"
write-host "Running avm.bat fmt" -ForegroundColor green  -BackgroundColor Blue
Start-Sleep 60

write-host "`n################################################`n"
write-host "Running avm.bat fmt" -ForegroundColor green  -BackgroundColor Blue
Start-Sleep 60
./avm.bat fmt

write-host "`n################################################`n"
write-host "Running avm.bat pre-commit" -ForegroundColor green  -BackgroundColor Blue
Start-Sleep 60
./avm.bat pre-commit

write-host "`n################################################`n"
write-host "Running avm.bat pr-check" -ForegroundColor green  -BackgroundColor Blue
Start-Sleep 60
./avm.bat pr-check

#>
terraform fmt -recursive
terraform-docs -c '.\.terraform-docs.yml' .
$docFolders = @("examples", "modules\vault_backup_policies")
foreach($folder in $docFolders){
    get-childItem -path $folder -Directory | % {echo "$($_.FullName)\"; terraform-docs -c '.\.terraform-docs.yml' "$($_.FullName)\"}
}
