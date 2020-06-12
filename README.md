This is a Powershell script to automate Static Bypass list.

Simply enter Proxy's IP and access credentials, then edit domains you want to exclude. Use task scheduler to run this script every
few minutes in some time range.

#Problem:
ProxyASG S200 has hardcoded limit of 2500 concurrent connections. When this number is reached proxy starts lagging and serving
simple content with big timeouts(somethimes 1-2 min for simple websites) making it completley unusable. With this script you can bypass
known good traffic (it's relative thinking but for me there is no point in intercepting google, facebook, twitter services...) and greately
improve proxy performance.

Forgive me for noobish scripting but solution was needed ASAP and this script was writen in less than an hour.


