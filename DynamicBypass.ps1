$pass = 'pass'
$env:Path +=";C:\Program Files (x86)\PuTTY"

function plink_it($command) { $command | plink admin@192.168.2.250 -pw $pass}  # main function that you pass commands to

$config = @("enable",$pass,"configure terminal","proxy-services","static-bypass") # array with some basic commands to configure static-bypass list
$view_current = $config + "view" + "?" # array of commands to view current bypass list
$backup = @("enable",$pass,"configure terminal","show configuration expanded noprompts with-keyrings unencrypted") # array of commands to view the backup
$test = @("enable",$pass,"configure terminal","?")
# This function deletes the Static-bypass list with user-defined exclusions (defined in ($_ -notmatch 'object'))
# To run it simply type in "plink_it_del"

function plink_it_del {
$backup_variable = plink_it $backup
$current_bypass_list = $backup_variable -match '^add\sall\s[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s\".+?\"'
# Reducet bypass list sets exclusions, which IPs you do not want to remove from static bypass list
$reduced_bypass_list = $current_bypass_list | ForEach-Object { if ($_ -notmatch '23.114.61.83' -and $_ -notmatch '23.114.61.82' -and $_ -notmatch '23.114.61.86') { $_ }}
$ip_to_remove = ([regex]"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}").Matches($reduced_bypass_list) | foreach-object {$_.Value}
$remove_feed = $ip_to_remove | ForEach-Object { "remove all $_" }
$del = $config + $remove_feed
plink_it $del
}
#plink_it_add function makes GET request for current connections and then parses only domains defined in $ToBypass object.
# You can do it for any port, not only 80 or 443.
# Make sure to enter correct credentials in Authorization header (Base64, admin:pass)
function plink_it_add {


##Getting the Active sessions via "HTTP GET"
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$A=Invoke-WebRequest -Uri "https://192.168.2.253:8082/AS/Sessions" -Headers @{
"Pragma"="no-cache"
  "Cache-Control"="no-cache"
  "Authorization"="Basic Rta46QkNBZG0xbNT"
  "Upgrade-Insecure-Requests"="1"
  "User-Agent"="Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36"
}; 

#Parse destination servers (OUTBOUND 443)
$ConnectionsToParse1=$A.ToString() | Select-String '(>.*\:443)|(>.*\:80)' -AllMatches | ForEach-Object {$_.Matches.Value}
#Remove leading ">"
$ConnectionsToParse2=$ConnectionsToParse1.Trim(">")
#Remove destination port from string
$ConnectionsToParse3=$ConnectionsToParse2.Trim(":443")
$ConnectionsToParse4=$ConnectionsToParse3.Trim(":80")
#Create object with unique values
$Connections=$ConnectionsToParse4 | Sort-Object -Unique

#Get only domains to bypass
$ToBypass=$Connections | Select-String '(.*trendmicro.com)|(.*google.com)|(.*gstatic.com)|(.*googlevideo.com)|(.*windows.com)|(.*googletagmanager.com)|(app-measurement.com)|(.*icloud.com)|(.*twitter.com)|(.*facebook.com)|(.*fbcdn.net)|(.*google.hr)|(.*gmail.com)|(.*googleapis.com)|(.*doubleclick.net)|(.*microsoft.com)|(.*office.com)|(.*dropbox.com)|(.*dropboxapi.com)|(.*linkedin.com)|(.*whatsapp.com)|(.*mozilla.com)|(.*mozilla.org)|(.*office365.com)|(.*windows.net)|(.*viber.com)|(.*samsung.com)|(.*google-analytics.com)|(.*youtube.com)|(.*live.com)|(.*huawei.com)|(.*googlesyndication.com)' -AllMatches | ForEach-Object {$_.Matches.Value}
#Reslove bypass domains to IP

$server_list = foreach ($server in $ToBypass) {
  $addresses = [System.Net.Dns]::GetHostAddresses($server)
  foreach($a in $addresses) {
    'add all {1} "{0}"' -f $server, $a.IPAddressToString                      # Resolved IPs are directly transformed into command "add all IPaddress "comment"
  }}
$add = $config + $server_list                                                 # Complete command to add servers into static bypass
plink_it $add                                                                 # ADD THEM! 
}

# This function backups the current configuration, recommended to call before other functions :P
# To run simply call "plink_it_backup"

function plink_it_backup {
plink_it $backup > "C:\Users\MackIT\Desktop\Backup\Backup-$(get-date -f dd-MM-yyyy).txt"         
}

#You can allways check for current configuration before/after calling functions e.g. plink_it $view_current, plink_it_add, plink_it $view_current, plink_it_del

#plink_it_backup
#plink_it_del
#plink_it_view
#plink_it_add
#plink_it $view_current
