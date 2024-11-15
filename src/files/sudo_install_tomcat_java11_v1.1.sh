#!/bin/bash

echo "Proceso 1 de 15: Actualizando los paquetes del sistema..."
sudo apt update -y

echo "Proceso 2 de 15: Verificando y agregando el repositorio de Debian unstable si es necesario..."
if ! grep -q "deb http://deb.debian.org/debian unstable main non-free contrib" /etc/apt/sources.list.d/unstable.list; then
    echo "Agregando el repositorio de Debian unstable..."
    echo "deb http://deb.debian.org/debian unstable main non-free contrib" | sudo tee /etc/apt/sources.list.d/unstable.list
    sudo apt update -y
else
    echo "El repositorio de Debian unstable ya está agregado."
fi

echo "Proceso 3 de 15: Verificando e instalando Java 11 si es necesario..."
if ! java -version 2>&1 | grep -q "openjdk version \"11\""; then
    echo "Instalando Java 11..."
    sudo apt install -y openjdk-11-jdk
else
    echo "Java 11 ya está instalado."
fi

echo "Proceso 4 de 15: Verificando la instalación de Java..."
java -version

echo "Proceso 5 de 15: Detectando la última versión de Apache Tomcat 9..."
TOMCAT_BASE_URL="https://dlcdn.apache.org/tomcat/tomcat-9/"
LATEST_VERSION=$(curl -s "$TOMCAT_BASE_URL" | grep -oP 'v9\.\d+\.\d+/' | sort -V | tail -n 1 | tr -d '/')
TOMCAT_ARCHIVE="apache-tomcat-$LATEST_VERSION.tar.gz"
TOMCAT_URL="$TOMCAT_BASE_URL$LATEST_VERSION/bin/$TOMCAT_ARCHIVE"

echo "La última versión detectada de Tomcat 9 es: $LATEST_VERSION"

echo "Proceso 6 de 15: Verificando y descargando Apache Tomcat $LATEST_VERSION si es necesario..."
if [ ! -f $TOMCAT_ARCHIVE ]; then
    echo "Descargando Apache Tomcat $LATEST_VERSION..."
    wget $TOMCAT_URL
else
    echo "El archivo de Apache Tomcat $LATEST_VERSION ya está descargado."
fi

echo "Proceso 7 de 15: Verificando y extrayendo Apache Tomcat $LATEST_VERSION si es necesario..."
if [ ! -d apache-tomcat-$LATEST_VERSION ]; then
    echo "Extrayendo Apache Tomcat $LATEST_VERSION..."
    tar xzf $TOMCAT_ARCHIVE
else
    echo "Apache Tomcat $LATEST_VERSION ya está extraído."
fi

echo "Proceso 8 de 15: Verificando y moviendo Apache Tomcat $LATEST_VERSION a /var/lib/tomcat9 si es necesario..."
if [ ! -d /var/lib/tomcat9 ]; then
    echo "Moviendo Apache Tomcat $LATEST_VERSION a /var/lib/tomcat9..."
    sudo mv apache-tomcat-$LATEST_VERSION /var/lib/tomcat9
else
    echo "Apache Tomcat $LATEST_VERSION ya está en /var/lib/tomcat9."
fi

echo "Proceso 9 de 15: Configurando permisos..."
sudo chown -R $USER:$USER /var/lib/tomcat9
sudo chmod +x /var/lib/tomcat9/bin/*.sh

echo "Proceso 10 de 15: Configurando variables de entorno..."
if [ ! -f /etc/profile.d/tomcat9.sh ]; then
    echo 'export CATALINA_HOME="/var/lib/tomcat9"' | sudo tee /etc/profile.d/tomcat9.sh
    echo 'export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"' | sudo tee -a /etc/profile.d/tomcat9.sh
    source /etc/profile.d/tomcat9.sh
else
    echo "Las variables de entorno ya están configuradas."
fi

echo "Proceso 11 de 15: Configurando usuarios de Tomcat..."
sudo tee /var/lib/tomcat9/conf/tomcat-users.xml > /dev/null <<EOL
<tomcat-users>
  <role rolename="manager-gui"/>
  <user username="manager" password="your_password" roles="manager-gui"/>
  <role rolename="admin-gui"/>
  <user username="admin" password="your_password" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOL

echo "Proceso 12 de 15: Eliminando la etiqueta Valve en context.xml si existe..."
sudo sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/d' /var/lib/tomcat9/webapps/manager/META-INF/context.xml

echo "Proceso 13 de 15: Creando el archivo de servicio para Tomcat..."
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOL
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
Environment=CATALINA_PID=/var/lib/tomcat9/temp/tomcat.pid
Environment=CATALINA_HOME=/var/lib/tomcat9
Environment=CATALINA_BASE=/var/lib/tomcat9
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/var/lib/tomcat9/bin/startup.sh
ExecStop=/var/lib/tomcat9/bin/shutdown.sh

User=$USER
Group=$USER
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOL

echo "Proceso 14 de 15: Recargando los archivos de servicio del sistema y habilitando el servicio Tomcat..."
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat

echo "Proceso 15 de 15: Verificando el estado del servicio Tomcat..."
if sudo systemctl is-enabled tomcat | grep -q "enabled"; then
    echo "El servicio Tomcat está habilitado para iniciarse automáticamente al arrancar el sistema."
else
    echo "El servicio Tomcat no está habilitado para iniciarse automáticamente al arrancar el sistema."
fi

sudo systemctl status tomcat

echo "Instalación y configuración de Tomcat $LATEST_VERSION completada."
