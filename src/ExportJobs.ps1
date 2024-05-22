0..-7 | % {

    $Date = (Get-Date -Hour 17 -Minute 0 -Second 0).AddDays($_)
    $Filename = $Date.GetDateTimeFormats('s').split('T')[0] + ".json"

    [System.Collections.ArrayList] $JobData = @()

    $JobsOnDay = Get-VBRBackupSession | ? {($_.SessionInfo.CreationTime -ge $Date) -and ($_.SessionInfo.CreationTime -lt $Date.AddDays(1)) -and ($_.IsRetryMode -eq $false)}

    foreach ($Job in $JobsOnDay) {

        Write-Host "Processing $($Date.ToShortDateString()) => $($Job.JobName)"

        $LastSessions = $Job.GetOriginalAndRetrySessions($true)
        $SessionType = $Job.Name.Replace($Job.JobName,"").Trim(" ()")
        $Type = $Job.JobTypeString
        $DisplayType = "$Type ($SessionType)"
        $StartTime = $LastSessions[0].CreationTime
        $EndTime = $LastSessions[-1].EndTime
        $Duration = ($EndTime - $StartTime).ToString("d' day(s) 'h' hour(s) 'mm' minute(s) 'ss' second(s)'")

        $props = @{
            Name = $Job.JobName
            Type = $Type
            DisplayType  = $DisplayType
            SessionType = $SessionType
            Duration = $Duration
            StartTimeLocal = $StartTime.ToString()        
            EndTimeLocal = $EndTime.ToString()
            StartTimeUTC = $StartTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            EndTimeUTC = $EndTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            Retry = $LastSessions[-1].IsRetryMode
            FullBackup = $LastSessions[0].IsFullMode
            Result = $LastSessions[-1].Result
            Notes = $LastSessions[-1].GetDetails()
        }

        $obj = New-Object -TypeName psobject -Property $props
        $JobData.Add($obj) | Out-Null
    }

    $JobData | ConvertTo-Json -Depth 100 | Out-File $Filename -Encoding utf8 -Force -Confirm:$false
}