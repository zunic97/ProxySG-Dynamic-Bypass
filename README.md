This is a Powershell script to automate Static Bypass list.

Simply enter Proxy's IP and access credentials, then edit domains you want to exclude. Use task scheduler to run this script every
few minutes in some time range.

#Example:
ProxyASG S200 has hardcoded limit of 2500 concurrent connections. When this number is reached proxy starts lagging and serving
simple content with big timeouts(somethimes 1-2 min for simple websites) making it completley unusable.

