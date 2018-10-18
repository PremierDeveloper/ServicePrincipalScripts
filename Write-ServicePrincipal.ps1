Function login ($user, $pass)
{
    $env = Get-AzureRmEnvironment 'AzureCloud'
    $IsMsAccount = Read-Host -Prompt 'Is this a Microsoft account (Live.com, Hotmail.com, etc) [Y/N]'
        
    if ($IsMsAccount -eq "Y")
    {
       $acct = Login-AzureRmAccount -Environment $env 
       return $acct
    }
    else
    {
       if(-Not($user -and $pass))
       {
           $user = Read-Host -Prompt 'Enter user name'
           $pass = Read-Host -Prompt 'Enter password'
       }
            
       $pw = ConvertTo-SecureString $pass -AsPlainText -Force
       $cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $user, $pw

       $acct = Login-AzureRmAccount -Environment $env -Credential $cred -ErrorAction Ignore
       return $acct     
    }
}

Function get-subscription ($subsname)
{
    if(-Not($subsname))
    {
        $subsname = Read-Host -Prompt 'Enter subscription name'
    }
    
    $subs = Get-AzureRmSubscription -SubscriptionName $subsname -ErrorAction Ignore

    if($subs -ne $null)
    {
        Write-Host "Subscription '$($subs.Name)' found." -ForegroundColor Green
    }
    else
    {
        Write-Host "Subscription was not found." -ForegroundColor Red
        Break
    }

    Set-AzureRmContext -Tenant $subs.TenantId -Subscription $subs.SubscriptionId
    
    return $subs
}

Function get-resourcegroup ($rgname)
{
    if(-Not($rgname))
    {
        $rgname = Read-Host -Prompt 'Enter resource group name'
    }
    
    $rg = Get-AzureRmResourceGroup -Name $rgname -ErrorAction Ignore
    return $rg
}

Function get-password ($pass)
{
    if(-Not($pass))
    {
        $pass = Read-Host -Prompt 'Enter password'
    }
    
    $pass = ConvertTo-SecureString $pass -AsPlainText -Force
    return $pass
}

Function get-displayname ($displayname)
{
    if(-Not($displayname))
    {
        $displayname = Read-Host -Prompt 'Enter display name'
    }
    
    return $displayname
}

Function get-domainname ($domainname)
{
    if(-Not($domainname))
    {
        $domainname = Read-Host -Prompt 'Enter domain name managed by AAD'
    }
    
    return $domainname
}

Function create-serviceprincipal ($sp_displayname, $sp_password, $sp_domain, $subsid)
{
    if(-Not($sp_displayname))
    {
        $sp_displayname = Read-Host -Prompt 'Enter service principal displayname'
    }

    if(-Not($sp_domain))
    {
        $sp_domain = Read-Host -Prompt 'Enter service principal domain'
    }
    
    $app = New-AzureRmADApplication -DisplayName $sp_displayname -HomePage "https://$sp_domain/$sp_displayname" -IdentifierUris "https://$sp_domain/$sp_displayname" -Password $sp_password 
   
    $sp = New-AzureRmADServicePrincipal -DisplayName $sp_displayname -Password $sp_password -ApplicationId $app.ApplicationId.Guid
       
    Start-Sleep -Seconds 15

    $scope = '/subscriptions/' + $subsid

    $ra = New-AzureRMRoleAssignment -RoleDefinitionName 'Contributor' -ServicePrincipalName $app.ApplicationId.Guid -Scope $scope -ErrorAction SilentlyContinue
    
    return $sp
}

Function get-serviceprincipal ($displayname)
{
    if(-Not($displayname))
    {
        $displayname = Read-Host -Prompt 'Enter displayname of service prinicipal'
    }
    
    $sp = Get-AzureRmADServicePrincipal -DisplayName $displayname 
        
    return $sp
}

Function remove-aad-application ($app_displayname)
{
    if(-Not($app_displayname))
    {
        $app_displayname = Read-Host -Prompt 'Enter application displayname'        
    }

    Remove-AzureRmADApplication -DisplayName $app_displayname -Force
}

#---------------  INPUT VALUES    --------------------#

$acc = login
$sub = get-subscription #-subsname 'name of your subscription'

$p = get-password #this will prompt for password or you can enter password here as a parameter
$name = get-displayname #-displayname 'displayname-of-registered-app'
$domain  = get-domainname #-domainname 'your-domain.com'


#-----------------------------------------------------#


$exist = get-serviceprincipal -displayname $name
if($exist -ne $null)
{
    Write-Host "App $($exist.DisplayName) already exists. Removing..."
    remove-aad-application -app_displayname $exist.DisplayName
}

Write-Host "App $name does not exists. Creating app $name ..."
$sp = create-serviceprincipal -sp_displayname $name -sp_domain $domain -subsid $sub.SubscriptionId -sp_password $p

Write-Output "-------------------------------"

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($p)
$unsecurep = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host "TenantId: $($sub.TenantId)" -ForegroundColor Yellow
Write-Host "SubscriptionId: $($sub.SubscriptionId)" -ForegroundColor Yellow
Write-Host "ClientId: $($sp.ApplicationId)" -ForegroundColor Yellow
Write-Host "Password: $unsecurep" -ForegroundColor Yellow

Write-Output "-------------------------------"