$secret = 'appsecret'
$appid = 'appid'
$redirect = 'https://login.microsoftonline.com/common/oauth2/nativeclient'
Function Show-OAuthWindow {
    param(
      [System.Uri]$Url
    )
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width = 440; Height = 640}
    $web = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width = 420; Height = 600; Url = ($url ) }
    $DocComp = {
        $Global:uri = $web.Url.AbsoluteUri
        if ($Global:Uri -match "error=[^&]*|code=[^&]*") {$form.Close() }
    }
    $web.ScriptErrorsSuppressed = $true
    $web.Add_DocumentCompleted($DocComp)
    $form.Controls.Add($web)
    $form.Add_Shown( {$form.Activate()})
    $form.ShowDialog() | Out-Null

    $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)    
    $output = @{}
    foreach ($key in $queryOutput.Keys) {
        $output["$key"] = $queryOutput[$key]
    }

    $output
}

if($PSVersionTable.PSEdition -eq 'Core') {
    "Please surf to https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=$appid&response_type=code&redirect_uri=$redirect&response_mode=query&scope=offline_access%20mail.read%20user.read%20calendars.read&state=12345"
    $null = Read-Host "press enter after signing in"

    if(Test-Path -Path "$Home/Downloads/nativeclient.dms") {
        $mdls = & mdls -name kMDItemWhereFroms $Home/Downloads/nativeclient.dms
        if(($mdls|select-string code=) -match "code=(.*)&state") {
          $code = $Matches[1]
        } else {
          $code = Read-Host "Could not validate code, please enter it"
        }
    }
} else {
  # The loginUrl to show the user
  Add-Type -AssemblyName System.Web
  $loginUrl = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=$appid&response_type=code&redirect_uri=$redirect&response_mode=query&scope=offline_access%20mail.read%20user.read%20calendars.read&state=12345"
  $queryOutput = Show-OAuthWindow -Url $loginUrl
  # We then get the code from the response of the login
  if ($null -eq $queryoutput -or $null -eq $queryOutput["code"] -or $queryOutput -eq "") {
      Write-Warning "No authorization code received from login"
      return
  }
  $code = $queryOutput["code"]
}

$body = @{'client_id'=$appid;grant_type='authorization_code';code=$code;redirect_uri=$redirect;scope='Calendars.Read Mail.Read User.Read profile openid email'}

$tokens = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/common/oauth2/v2.0/token" -Body $body -ContentType 'application/x-www-form-urlencoded'
$uri = "https://graph.microsoft.com/beta/me/calendar/calendarView?startDateTime=$startdate&endDateTime=$enddate"
$calendarData = Invoke-RestMethod -Uri $uri -headers @{'Authorization'="Bearer $($tokens.access_token)"}

#Or if you want data from a teams chat you can grab that thru
$teamsChatData = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/me/chats/$id/messages" -headers @{'Authorization'="Bearer $($script:tokens.access_token)"} -ResponseHeadersVariable ResHeaders
