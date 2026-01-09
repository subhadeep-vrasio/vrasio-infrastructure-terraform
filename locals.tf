
## Working all without Redis

locals {
  web_user_data = <<-EOF
    #!/bin/bash
    LOG=/var/log/user-data.log
    echo "Starting user-data script" > $LOG

    # -------------------------------
    # System update
    # -------------------------------
    dnf update -y >> $LOG 2>&1

    # -------------------------------
    # Apache Installation
    # -------------------------------
    dnf install -y httpd >> $LOG 2>&1
    systemctl enable httpd >> $LOG 2>&1
    systemctl start httpd >> $LOG 2>&1

    # Force correct DocumentRoot (necessary for Laravel)
    sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/var/www/html"|g' /etc/httpd/conf/httpd.conf
    sed -i 's|<Directory "/var/www">|<Directory "/var/www/html">|g' /etc/httpd/conf/httpd.conf
    rm -f /usr/share/httpd/noindex/index.html >> $LOG 2>&1

    # -------------------------------
    # PHP Installation (AL2023 native)
    # -------------------------------
    dnf install -y \
      php \
      php-cli \
      php-fpm \
      php-mysqlnd \
      php-devel \
      php-pear \
      php-redis >> $LOG 2>&1

    # -------------------------------
    # Install ImageMagick + HEIC dependencies
    # -------------------------------
    dnf install -y \
      ImageMagick \
      ImageMagick-devel \
      libheif \
      libheif-devel >> $LOG 2>&1

    # -------------------------------
    # Install Imagick PHP extension
    # -------------------------------
    printf "\n" | pecl install imagick >> $LOG 2>&1
    echo "extension=imagick.so" | sudo tee /etc/php.d/20-imagick.ini >> $LOG 2>&1

    # -------------------------------
    # Check if ImageMagick has HEIC support
    # -------------------------------
    convert -list format | grep HEIC >> $LOG 2>&1
    if [ $? -eq 0 ]; then
      echo "Imagick installed with HEIC support ✅" >> $LOG
    else
      echo "Imagick installed without HEIC support ❌" >> $LOG
    fi

    # -------------------------------
    # Install Redis from source
    # -------------------------------
    dnf install -y gcc make jemalloc-devel >> $LOG 2>&1
    cd /usr/local/src
    wget http://download.redis.io/redis-stable.tar.gz >> $LOG 2>&1
    tar xzvf redis-stable.tar.gz >> $LOG 2>&1
    cd redis-stable
    make >> $LOG 2>&1
    make install >> $LOG 2>&1

    # -------------------------------
    # Create Redis configuration and directories
    # -------------------------------
    mkdir -p /var/lib/redis
    mkdir -p /etc/redis
    cp redis.conf /etc/redis/ >> $LOG 2>&1

    # -------------------------------
    # Redis systemd service setup
    # -------------------------------
    cat <<'SERVICE' > /etc/systemd/system/redis.service
    [Unit]
    Description=Redis In-Memory Data Store
    After=network.target

    [Service]
    ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
    ExecStop=/usr/local/bin/redis-server /etc/redis/redis.conf shutdown
    Restart=always
    User=redis
    Group=redis

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # -------------------------------
    # Enable and start Redis service
    # -------------------------------
    systemctl daemon-reload >> $LOG 2>&1
    systemctl enable redis >> $LOG 2>&1
    systemctl start redis >> $LOG 2>&1

    # Check Redis status
    echo "Checking Redis status..." >> $LOG
    systemctl status redis >> $LOG 2>&1
    if ! systemctl is-active --quiet redis; then
        echo "Redis is not running, attempting to restart..." >> $LOG
        systemctl restart redis >> $LOG 2>&1
    fi

    # -------------------------------
    # Supervisor via pip
    # -------------------------------
    dnf install -y python3 python3-pip >> $LOG 2>&1
    pip3 install supervisor >> $LOG 2>&1

    mkdir -p /etc/supervisor
    mkdir -p /etc/supervisor/conf.d
    mkdir -p /var/log/supervisor

    # -------------------------------
    # Supervisor systemd service
    # -------------------------------
    cat <<'SERVICE' > /etc/systemd/system/supervisord.service
    [Unit]
    Description=Supervisor daemon
    After=network.target

    [Service]
    Type=forking
    ExecStart=/usr/local/bin/supervisord -c /etc/supervisor/supervisord.conf
    ExecStop=/usr/local/bin/supervisorctl shutdown
    ExecReload=/usr/local/bin/supervisorctl reload
    KillMode=process
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # -------------------------------
    # Supervisor main config
    # -------------------------------
    cat <<'CONF' > /etc/supervisor/supervisord.conf
    [unix_http_server]
    file=/var/run/supervisor.sock

    [supervisord]
    logfile=/var/log/supervisor/supervisord.log
    pidfile=/var/run/supervisord.pid
    childlogdir=/var/log/supervisor

    [rpcinterface:supervisor]
    supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

    [supervisorctl]
    serverurl=unix:///var/run/supervisor.sock

    [include]
    files = /etc/supervisor/conf.d/*.conf
    CONF

    systemctl daemon-reload >> $LOG 2>&1
    systemctl enable supervisord >> $LOG 2>&1
    systemctl start supervisord >> $LOG 2>&1

    # -------------------------------
    # Permissions (DEV)
    # -------------------------------
    usermod -a -G apache ec2-user >> $LOG 2>&1
    chown -R apache:apache /var/www/html >> $LOG 2>&1
    chmod -R 755 /var/www/html >> $LOG 2>&1
    chmod -R 775 /var/www/html >> $LOG 2>&1

    # -------------------------------
    # Create index.php (Infra Check)
    # -------------------------------
    cat <<'PHPINFO' > /var/www/html/index.php
    <?php
    echo "<h2>DEV Infrastructure</h2><hr>";

    echo "PHP Version: " . PHP_VERSION . "<br>";

    echo extension_loaded('redis')
        ? "Redis PHP extension loaded ✅<br>"
        : "Redis PHP extension NOT loaded ❌<br>";

    echo trim(shell_exec('redis-cli ping')) === "PONG"
        ? "Redis server running ✅<br>"
        : "Redis server NOT responding ❌<br>";

    echo extension_loaded('imagick')
        ? "Imagick loaded ✅<br>"
        : "Imagick NOT loaded ❌<br>";

    $supervisorPid = trim(shell_exec('pgrep supervisord'));
    echo !empty($supervisorPid)
        ? "Supervisor running ✅ (PID: $supervisorPid)<br>"
        : "Supervisor NOT running ❌<br>";
    ?>
    PHPINFO

    systemctl restart httpd >> $LOG 2>&1

    echo "User-data completed successfully" >> $LOG
  EOF
}

# locals {
#   web_user_data = <<-EOF
#     #!/bin/bash
#     LOG=/var/log/user-data.log
#     echo "Starting user-data script" > $LOG

#     # -------------------------------
#     # System update
#     # -------------------------------
#     dnf update -y >> $LOG 2>&1

#     # -------------------------------
#     # Apache Installation
#     # -------------------------------
#     dnf install -y httpd >> $LOG 2>&1
#     systemctl enable httpd >> $LOG 2>&1
#     systemctl start httpd >> $LOG 2>&1

#     # Force correct DocumentRoot (necessary for Laravel)
#     sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/var/www/html"|g' /etc/httpd/conf/httpd.conf
#     sed -i 's|<Directory "/var/www">|<Directory "/var/www/html">|g' /etc/httpd/conf/httpd.conf
#     rm -f /usr/share/httpd/noindex/index.html >> $LOG 2>&1

#     # -------------------------------
#     # PHP Installation (AL2023 native)
#     # -------------------------------
#     dnf install -y \
#       php \
#       php-cli \
#       php-fpm \
#       php-mysqlnd \
#       php-devel \
#       php-pear \
#       php-redis >> $LOG 2>&1

#     # -------------------------------
#     # Install ImageMagick + HEIC dependencies
#     # -------------------------------
#     dnf install -y \
#       ImageMagick \
#       ImageMagick-devel \
#       libheif \
#       libheif-devel >> $LOG 2>&1

#     # -------------------------------
#     # Install Imagick PHP extension
#     # -------------------------------
#     printf "\n" | pecl install imagick >> $LOG 2>&1
#     echo "extension=imagick.so" | sudo tee /etc/php.d/20-imagick.ini >> $LOG 2>&1

#     # -------------------------------
#     # Check if ImageMagick has HEIC support
#     # -------------------------------
#     convert -list format | grep HEIC >> $LOG 2>&1
#     if [ $? -eq 0 ]; then
#       echo "Imagick installed with HEIC support ✅" >> $LOG
#     else
#       echo "Imagick installed without HEIC support ❌" >> $LOG
#     fi

#     # -------------------------------
#     # Install Redis from source
#     # -------------------------------
#     dnf install -y gcc make jemalloc-devel >> $LOG 2>&1
#     cd /usr/local/src
#     wget http://download.redis.io/redis-stable.tar.gz >> $LOG 2>&1
#     tar xzvf redis-stable.tar.gz >> $LOG 2>&1
#     cd redis-stable
#     make >> $LOG 2>&1
#     make install >> $LOG 2>&1

#     # -------------------------------
#     # Create Redis configuration and directories
#     # -------------------------------
#     mkdir -p /var/lib/redis
#     mkdir -p /etc/redis
#     cp redis.conf /etc/redis/ >> $LOG 2>&1

#     # -------------------------------
#     # Create Redis user and group (if not already)
#     # -------------------------------
#     usermod -aG redis redis >> $LOG 2>&1
#     groupadd redis || true >> $LOG 2>&1
#     useradd redis || true >> $LOG 2>&1
#     chown -R redis:redis /var/lib/redis >> $LOG 2>&1
#     chmod -R 700 /var/lib/redis >> $LOG 2>&1

#     # -------------------------------
#     # Redis systemd service setup
#     # -------------------------------
#     cat <<'SERVICE' > /etc/systemd/system/redis.service
#     [Unit]
#     Description=Redis In-Memory Data Store
#     After=network.target

#     [Service]
#     ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
#     ExecStop=/usr/local/bin/redis-server /etc/redis/redis.conf shutdown
#     Restart=always
#     User=redis
#     Group=redis

#     [Install]
#     WantedBy=multi-user.target
#     SERVICE

#     # -------------------------------
#     # Enable and start Redis service
#     # -------------------------------
#     systemctl daemon-reload >> $LOG 2>&1
#     systemctl enable redis >> $LOG 2>&1
#     systemctl start redis >> $LOG 2>&1

#     # Check Redis status
#     echo "Checking Redis status..." >> $LOG
#     systemctl status redis >> $LOG 2>&1
#     if ! systemctl is-active --quiet redis; then
#         echo "Redis is not running, attempting to restart..." >> $LOG
#         systemctl restart redis >> $LOG 2>&1
#     fi

#     # -------------------------------
#     # Supervisor via pip
#     # -------------------------------
#     dnf install -y python3 python3-pip >> $LOG 2>&1
#     pip3 install supervisor >> $LOG 2>&1

#     mkdir -p /etc/supervisor
#     mkdir -p /etc/supervisor/conf.d
#     mkdir -p /var/log/supervisor

#     # -------------------------------
#     # Supervisor systemd service
#     # -------------------------------
#     cat <<'SERVICE' > /etc/systemd/system/supervisord.service
#     [Unit]
#     Description=Supervisor daemon
#     After=network.target

#     [Service]
#     Type=forking
#     ExecStart=/usr/local/bin/supervisord -c /etc/supervisor/supervisord.conf
#     ExecStop=/usr/local/bin/supervisorctl shutdown
#     ExecReload=/usr/local/bin/supervisorctl reload
#     KillMode=process
#     Restart=on-failure

#     [Install]
#     WantedBy=multi-user.target
#     SERVICE

#     # -------------------------------
#     # Supervisor main config
#     # -------------------------------
#     cat <<'CONF' > /etc/supervisor/supervisord.conf
#     [unix_http_server]
#     file=/var/run/supervisor.sock

#     [supervisord]
#     logfile=/var/log/supervisor/supervisord.log
#     pidfile=/var/run/supervisord.pid
#     childlogdir=/var/log/supervisor

#     [rpcinterface:supervisor]
#     supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

#     [supervisorctl]
#     serverurl=unix:///var/run/supervisor.sock

#     [include]
#     files = /etc/supervisor/conf.d/*.conf
#     CONF

#     systemctl daemon-reload >> $LOG 2>&1
#     systemctl enable supervisord >> $LOG 2>&1
#     systemctl start supervisord >> $LOG 2>&1

#     # -------------------------------
#     # Permissions (DEV)
#     # -------------------------------
#     usermod -a -G apache ec2-user >> $LOG 2>&1
#     chown -R apache:apache /var/www/html >> $LOG 2>&1
#     chmod -R 755 /var/www/html >> $LOG 2>&1
#     chmod -R 775 /var/www/html >> $LOG 2>&1

#     # -------------------------------
#     # Create index.php (Infra Check)
#     # -------------------------------
#     cat <<'PHPINFO' > /var/www/html/index.php
#     <?php
#     echo "<h2>DEV Infrastructure</h2><hr>";

#     echo "PHP Version: " . PHP_VERSION . "<br>";

#     echo extension_loaded('redis')
#         ? "Redis PHP extension loaded ✅<br>"
#         : "Redis PHP extension NOT loaded ❌<br>";

#     echo trim(shell_exec('redis-cli ping')) === "PONG"
#         ? "Redis server running ✅<br>"
#         : "Redis server NOT responding ❌<br>";

#     echo extension_loaded('imagick')
#         ? "Imagick loaded ✅<br>"
#         : "Imagick NOT loaded ❌<br>";

#     // Imagick HEIC Support Check
#     $imagick = new Imagick();
#     $formats = $imagick->queryFormats(); // List all supported formats

#     if (in_array('HEIC', $formats)) {
#         echo "HEIC is supported!<br>";
#     } else {
#         echo "HEIC is NOT supported!<br>";
#     }

#     $supervisorPid = trim(shell_exec('pgrep supervisord'));
#     echo !empty($supervisorPid)
#         ? "Supervisor running ✅ (PID: $supervisorPid)<br>"
#         : "Supervisor NOT running ❌<br>";
#     ?>
#     PHPINFO

#     systemctl restart httpd >> $LOG 2>&1

#     echo "User-data completed successfully" >> $LOG
#   EOF
# }


# locals {
#   web_user_data = <<-EOF
#     #!/bin/bash
#     LOG=/var/log/user-data.log
#     echo "Starting user-data script" > $LOG

#     # -------------------------------
#     # System update
#     # -------------------------------
#     dnf update -y >> $LOG 2>&1

#     # -------------------------------
#     # Apache Installation
#     # -------------------------------
#     dnf install -y httpd >> $LOG 2>&1
#     systemctl enable httpd >> $LOG 2>&1
#     systemctl start httpd >> $LOG 2>&1

#     # Force correct DocumentRoot (necessary for Laravel)
#     sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/var/www/html"|g' /etc/httpd/conf/httpd.conf
#     sed -i 's|<Directory "/var/www">|<Directory "/var/www/html">|g' /etc/httpd/conf/httpd.conf
#     rm -f /usr/share/httpd/noindex/index.html >> $LOG 2>&1

#     # -------------------------------
#     # PHP Installation (AL2023 native)
#     # -------------------------------
#     dnf install -y \
#       php \
#       php-cli \
#       php-fpm \
#       php-mysqlnd \
#       php-devel \
#       php-pear \
#       php-redis >> $LOG 2>&1

#     # -------------------------------
#     # Install ImageMagick + HEIC dependencies
#     # -------------------------------
#     dnf install -y \
#       ImageMagick \
#       ImageMagick-devel \
#       libheif \
#       libheif-devel >> $LOG 2>&1

#     # -------------------------------
#     # Install Imagick PHP extension
#     # -------------------------------
#     printf "\n" | pecl install imagick >> $LOG 2>&1
#     echo "extension=imagick.so" | sudo tee /etc/php.d/20-imagick.ini >> $LOG 2>&1

#     # -------------------------------
#     # Check if ImageMagick has HEIC support
#     # -------------------------------
#     convert -list format | grep HEIC >> $LOG 2>&1
#     if [ $? -eq 0 ]; then
#       echo "Imagick installed with HEIC support ✅" >> $LOG
#     else
#       echo "Imagick installed without HEIC support ❌" >> $LOG
#     fi

#     # -------------------------------
#     # Install Redis from source
#     # -------------------------------
#     dnf install -y gcc make jemalloc-devel >> $LOG 2>&1
#     cd /usr/local/src
#     wget http://download.redis.io/redis-stable.tar.gz >> $LOG 2>&1
#     tar xzvf redis-stable.tar.gz >> $LOG 2>&1
#     cd redis-stable
#     make >> $LOG 2>&1
#     make install >> $LOG 2>&1

#     # -------------------------------
#     # Create Redis user and group (if not already)
#     # -------------------------------
#     groupadd redis || true >> $LOG 2>&1
#     useradd -g redis redis || true >> $LOG 2>&1

#     # -------------------------------
#     # Create the Redis directory
#     # -------------------------------
#     mkdir -p /var/lib/redis >> $LOG 2>&1

#     # -------------------------------
#     # Set proper Redis permissions
#     # -------------------------------
#     chown -R redis:redis /var/lib/redis >> $LOG 2>&1
#     chmod -R 700 /var/lib/redis >> $LOG 2>&1

#     # -------------------------------
#     # Redis systemd service setup
#     # -------------------------------
#     cat <<'SERVICE' > /etc/systemd/system/redis.service
#     [Unit]
#     Description=Redis In-Memory Data Store
#     After=network.target

#     [Service]
#     ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
#     ExecStop=/usr/local/bin/redis-server /etc/redis/redis.conf shutdown
#     Restart=always
#     User=redis
#     Group=redis

#     [Install]
#     WantedBy=multi-user.target
#     SERVICE

#     # -------------------------------
#     # Enable and start Redis service
#     # -------------------------------
#     systemctl daemon-reload >> $LOG 2>&1
#     systemctl enable redis >> $LOG 2>&1
#     systemctl start redis >> $LOG 2>&1

#     # Check Redis status
#     echo "Checking Redis status..." >> $LOG
#     systemctl status redis >> $LOG 2>&1
#     if ! systemctl is-active --quiet redis; then
#         echo "Redis is not running, attempting to restart..." >> $LOG
#         systemctl restart redis >> $LOG 2>&1
#     fi

#     # -------------------------------
#     # Supervisor via pip
#     # -------------------------------
#     dnf install -y python3 python3-pip >> $LOG 2>&1
#     pip3 install supervisor >> $LOG 2>&1

#     mkdir -p /etc/supervisor
#     mkdir -p /etc/supervisor/conf.d
#     mkdir -p /var/log/supervisor

#     # -------------------------------
#     # Supervisor systemd service
#     # -------------------------------
#     cat <<'SERVICE' > /etc/systemd/system/supervisord.service
#     [Unit]
#     Description=Supervisor daemon
#     After=network.target

#     [Service]
#     Type=forking
#     ExecStart=/usr/local/bin/supervisord -c /etc/supervisor/supervisord.conf
#     ExecStop=/usr/local/bin/supervisorctl shutdown
#     ExecReload=/usr/local/bin/supervisorctl reload
#     KillMode=process
#     Restart=on-failure

#     [Install]
#     WantedBy=multi-user.target
#     SERVICE

#     # -------------------------------
#     # Supervisor main config
#     # -------------------------------
#     cat <<'CONF' > /etc/supervisor/supervisord.conf
#     [unix_http_server]
#     file=/var/run/supervisor.sock

#     [supervisord]
#     logfile=/var/log/supervisor/supervisord.log
#     pidfile=/var/run/supervisord.pid
#     childlogdir=/var/log/supervisor

#     [rpcinterface:supervisor]
#     supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

#     [supervisorctl]
#     serverurl=unix:///var/run/supervisor.sock

#     [include]
#     files = /etc/supervisor/conf.d/*.conf
#     CONF

#     systemctl daemon-reload >> $LOG 2>&1
#     systemctl enable supervisord >> $LOG 2>&1
#     systemctl start supervisord >> $LOG 2>&1

#     # -------------------------------
#     # Permissions (DEV)
#     # -------------------------------
#     usermod -a -G apache ec2-user >> $LOG 2>&1
#     chown -R apache:apache /var/www/html >> $LOG 2>&1
#     chmod -R 755 /var/www/html >> $LOG 2>&1
#     chmod -R 775 /var/www/html >> $LOG 2>&1

#     # -------------------------------
#     # Create index.php (Infra Check)
#     # -------------------------------
#     cat <<'PHPINFO' > /var/www/html/index.php
#     <?php
#     echo "<h2>DEV Infrastructure</h2><hr>";

#     echo "PHP Version: " . PHP_VERSION . "<br>";

#     echo extension_loaded('redis')
#         ? "Redis PHP extension loaded ✅<br>"
#         : "Redis PHP extension NOT loaded ❌<br>";

#     echo trim(shell_exec('redis-cli ping')) === "PONG"
#         ? "Redis server running ✅<br>"
#         : "Redis server NOT responding ❌<br>";

#     echo extension_loaded('imagick')
#         ? "Imagick loaded ✅<br>"
#         : "Imagick NOT loaded ❌<br>";

#     // Imagick HEIC Support Check
#     $imagick = new Imagick();
#     $formats = $imagick->queryFormats(); // List all supported formats

#     if (in_array('HEIC', $formats)) {
#         echo "HEIC is supported!<br>";
#     } else {
#         echo "HEIC is NOT supported!<br>";
#     }

#     $supervisorPid = trim(shell_exec('pgrep supervisord'));
#     echo !empty($supervisorPid)
#         ? "Supervisor running ✅ (PID: $supervisorPid)<br>"
#         : "Supervisor NOT running ❌<br>";
#     ?>
#     PHPINFO

#     systemctl restart httpd >> $LOG 2>&1

#     echo "User-data completed successfully" >> $LOG
#   EOF
# }
