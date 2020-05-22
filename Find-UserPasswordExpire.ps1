function Find-UserPasswordExpire
{

    Param
    (
        [string]$UserGroup,
        [string]$MailSender,
        [string]$MailServer,
        [string]$MailSubject,
        [string]$NotificationTemplate,
        [int]$FinalDate
    )

    Begin
    {
        $list = Get-ADGroupMember -Identity $UserGroup -Recursive | Where-Object -FilterScript {$_.objectClass -eq 'user'} | Get-ADUser -Properties msDS-UserPasswordExpiryTimeComputed, EmailAddress |
        Select-Object -Property "EmailAddress",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
        $date = Get-Date

    }
    Process
    {
        foreach ($user in $list) {
            $expires = (New-TimeSpan -Start $date -End $user.ExpiryDate).Days
            if ($expires -eq 30 -or $expires -eq 7 -or $expires -le $FinalDate -and $expires -ge 0) {
                Send-MailMessage -From $MailSender -To $user.EmailAddress -Subject $MailSubject -SmtpServer $MailServer -Encoding UTF8 -BodyAsHtml -Body ((Get-Content -Path $NotificationTemplate) -replace 'EXPIRYTIME',$expires | Out-String)
            }
        }
    }
    End
    {
    }
}
#Find-UserPasswordExpire -Group 'Group-containing-users' -MailServer 'smtp.company.tld' -MailSender 'noreply@company.tld' -MailSubject 'Your password is about to expire' -NotificationTemplate '.\notification.html' -FinalDate 3
