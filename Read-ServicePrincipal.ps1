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

Function get-tenant-id-from-domainname ($tenantid, $domainname)
{
    if($tenantid)
    {
        return $tenantid
    }
    else
    {
        if(-Not($domainname))
        {
            $domainname = Read-Host -Prompt 'Enter domain managed by the tenant'
        }
       
        $Response = Invoke-WebRequest -UseBasicParsing -Uri "https://login.windows.net/$domainname/.well-known/openid-configuration" -Method Get
        $json = ConvertFrom-Json -InputObject $Response.Content
        $t = $json.token_endpoint.split('/')[3]
        return $t
    }
}

Function get-subscription ($subsname)
{
    if(-Not($subsname))
    {
        $subsname = Read-Host -Prompt 'Enter subscription name'
    }
    
    $subs = Get-AzureRmSubscription -SubscriptionName $subsname -ErrorAction Ignore

    if($sub -ne $null)
    {
        Write-Host "Subscription '$($sub.Name)' found." -ForegroundColor Green
    }
    else
    {
        Write-Host "Subscription was not found." -ForegroundColor Red
        Break
    }

    Set-AzureRmContext -Tenant $sub.TenantId -Subscription $sub.SubscriptionId
    
    return $subs
}

Function get-serviceprincipal ($displayname)
{
    if(-Not($displayname))
    {
        $displayname = Read-Host -Prompt 'Enter displayname of service prinicipal'
    }
    
    $sp = Get-AzureRmADServicePrincipal -DisplayName $displayname -ErrorAction Ignore
    
    if($sp -ne $null)
    {
        Write-Host "Service principal '$($sp.DisplayName)' found." -ForegroundColor Green
    }
    else
    {
        Write-Host "Service principal was not found." -ForegroundColor Red
        Break
    }
    
    return $sp
}

#---------------  INPUT VALUES    --------------------#

$acc = login
$sub = get-subscription 'MSDN'

$sp = get-serviceprincipal -displayname 'automation-deployments'

#-----------------------------------------------------#


Write-Output "-------------------------------"

Write-Host "TenantId: $($sub.TenantId)" -ForegroundColor Yellow
Write-Host "SubscriptionId: $($sub.SubscriptionId)" -ForegroundColor Yellow
Write-Host "ClientId: $($sp.ApplicationId)" -ForegroundColor Yellow
Write-Host "Password: <password cannot be displayed>" -ForegroundColor Yellow

Write-Output "-------------------------------"