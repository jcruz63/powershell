##run once at start
##Connect-AzureAD -Confirm

cd C:\students

$list = Import-Csv -Path .\students.csv
$students = @()
$newStudents = @()

foreach($row in $list){
    $name = $row.first + " " + $row.last;
    $su = Get-AzureAdUser -Filter "startswith(displayName, '$name')" ; 
    if($su) {
    $su | Add-Member -NotePropertyName "Advisory" -NotePropertyValue $row.Advisory -Force
    $students += $su}
    else{
        $newStudents += $row
    }
}

$securepass = ConvertTo-SecureString "TempTFA123" -AsPlainText -Force

foreach($su in $students) {
    Set-AzureADUserPassword -ObjectId $su.ObjectId -Password  $securepass
    $su | Add-Member -NotePropertyName "TempPassword" -NotePropertyValue $temp
}
$temp = "TempTFA123"
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = $temp
$PasswordProfile.ForceChangePasswordNextLogin = $true

$accountsCreated = @();

foreach($student in $newStudents){
    

    $rand = Get-Random -Maximum 99;
    $name = $student.first + " " + $student.last;
    $nickName = $student.first[0] +  $student.last + $rand ;
    $email =  $nickName + "@foundationacademy.com";
    $account = New-AzureADUser -AccountEnabled $true -DisplayName $name -Department $student.Advisory -UserPrincipalName $email -PasswordProfile $PasswordProfile -MailNickName $nickName -UsageLocation US

    $LicensedUser = Get-AzureADUser -ObjectId "jdoe@foundationacademy.com" 
    $License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense 
    $License.SkuId = $LicensedUser.AssignedLicenses.SkuId 
    $Licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $Licenses.AddLicenses = $License
    Set-AzureADUserLicense -ObjectId $account.ObjectId -AssignedLicenses $Licenses

    $account | Add-Member -NotePropertyName "Advisory" -NotePropertyValue $student.Advisory -Force
    $account | Add-Member -NotePropertyName "TempPassword" -NotePropertyValue $temp -Force

    $accountsCreated += $account
}

$accountsCreated | Select-Object -Property DisplayName,USerPrincipalName,TempPassword,Advisory | Export-Csv -Path .\newAccounts.csv -NoTypeInformation
$students | Select-Object -Property DisplayName,USerPrincipalName,TempPassword,Advisory | Export-Csv -Path .\passwordResets.csv -NoTypeInformation

