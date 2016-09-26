





/usr/sbin/setsebool httpd_can_network_connect true


######################################################################
#   Reservas lifísticas
######################################################################
<VirtualHost r.atamvirtual.com.ar:80>
    ServerName r.atamvirtual.com.ar
    #DocumentRoot 
    #ServerAdmin w@hipermegared.com.ar
    
    #<Location />
    #Deny from all
    # Allow from (You may set IP here / to access without password)
    #AuthUserFile /var/www/html/tiquete/.htpassword
    #AuthName authorization
    #AuthType Basic
    #Satisfy Any 
    # (or all, if IPs specified and require IP + pass)
    # any means neither ip nor pass
    #require valid-user
    #</Location>
    
    <Proxy *>
        Order allow,deny
        Allow from all
    </Proxy>
    ProxyPass / http://localhost:5000/
    ProxyPassReverse / http://localhost:5000/
    AddOutputFilterByType SUBSTITUTE text/html
    Substitute "s|localhost:5000/|r.atamvirtual.com.ar/|i"

    ErrorLog  /var/log/reservas.log
    CustomLog  /var/log/reservas.log common
</VirtualHost>



