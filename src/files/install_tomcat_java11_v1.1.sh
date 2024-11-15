#!/bin/bash

echo "Proceso 1 de 16: Actualizando los paquetes del sistema..."
apt update -y

echo "Proceso 2 de 16: Instalando curl si no está instalado..."
apt install -y curl

echo "Proceso 3 de 16: Verificando y agregando el repositorio de Debian unstable si es necesario..."
if ! grep -q "deb http://deb.debian.org/debian unstable main non-free contrib" /etc/apt/sources.list.d/unstable.list; then
    echo "Agregando el repositorio de Debian unstable..."
    echo "deb http://deb.debian.org/debian unstable main non-free contrib" | tee /etc/apt/sources.list.d/unstable.list
    apt update -y
else
    echo "El repositorio de Debian unstable ya está agregado."
fi

echo "Proceso 4 de 16: Verificando si Java 11 ya está instalado..."
if ! java -version 2>&1 | grep -q "openjdk version \"11\""; then
    echo "Instalando Java 11..."
    apt install -y openjdk-11-jdk
else
    echo "Java 11 ya está instalado."
fi

echo "Proceso 5 de 16: Verificando la instalación de Java..."
java -version

echo "Proceso 6 de 16: Verificando si Apache Tomcat 9 ya está instalado..."
if [ -d "/var/lib/tomcat9" ]; then
    echo "Apache Tomcat 9 ya está instalado en /var/lib/tomcat9. Saltando descarga."
else
    echo "Proceso 7 de 16: Detectando la última versión de Tomcat 9..."
    VERSION=$(curl -s https://dlcdn.apache.org/tomcat/tomcat-9/ | grep -oP 'v9\.\d+\.\d+' | tail -1)
    if [ -z "$VERSION" ]; then
        echo "No se pudo encontrar la última versión de Tomcat 9. Abortando."
        exit 1
    fi
    echo "La última versión detectada de Tomcat 9 es: $VERSION"

    echo "Proceso 8 de 16: Verificando y descargando Apache Tomcat si es necesario..."
    URL="https://dlcdn.apache.org/tomcat/tomcat-9/$VERSION/bin/apache-tomcat-${VERSION#v}.tar.gz"
    if [ ! -f "apache-tomcat-${VERSION#v}.tar.gz" ]; then
        echo "Descargando Apache Tomcat desde $URL..."
        curl -O $URL
        if [ $? -ne 0 ]; then
            echo "Error al descargar Apache Tomcat. Verifica la URL o tu conexión a Internet."
            exit 1
        fi
    else
        echo "El archivo de Apache Tomcat ya está descargado."
    fi

    echo "Proceso 9 de 16: Verificando que el archivo descargado esté en formato gzip..."
    if ! file apache-tomcat-${VERSION#v}.tar.gz | grep -q 'gzip compressed data'; then
        echo "El archivo descargado no está en formato gzip válido. Verifica la URL de descarga."
        rm -f apache-tomcat-${VERSION#v}.tar.gz
        exit 1
    fi

    echo "Proceso 10 de 16: Verificando y extrayendo Apache Tomcat si es necesario..."
    if [ ! -d "apache-tomcat-$VERSION" ]; then
        echo "Extrayendo Apache Tomcat..."
        tar xzf "apache-tomcat-${VERSION#v}.tar.gz"
        if [ $? -ne 0 ]; then
            echo "Error al extraer el archivo. Asegúrate de que se descargó correctamente."
            exit 1
        fi
    else
        echo "Apache Tomcat ya está extraído."
    fi

    echo "Proceso 11 de 16: Verificando y moviendo Apache Tomcat a /var/lib/tomcat9 si es necesario..."
    if [ ! -d /var/lib/tomcat9 ]; then
        echo "Moviendo Apache Tomcat a /var/lib/tomcat9..."
        mv "apache-tomcat-$VERSION" /var/lib/tomcat9
        if [ $? -ne 0 ]; then
            echo "No se pudo mover la carpeta Tomcat. Intentando copiarla..."
            cp -r "apache-tomcat-$VERSION" /var/lib/tomcat9
            if [ $? -ne 0 ]; then
                echo "Error al copiar la carpeta Tomcat. Abortando."
                exit 1
            fi
            echo "Carpeta Tomcat copiada con éxito."
        else
            echo "Apache Tomcat movido a /var/lib/tomcat9."
        fi
    else
        echo "Apache Tomcat ya está en /var/lib/tomcat9."
    fi
fi

echo "Proceso 12 de 16: Configurando permisos..."
chown -R $USER:$USER /var/lib/tomcat9
chmod +x /var/lib/tomcat9/bin/*.sh

echo "Proceso 13 de 16: Configurando variables de entorno..."
if [ ! -f /etc/profile.d/tomcat9.sh ]; then
    echo 'export CATALINA_HOME="/var/lib/tomcat9"' | tee /etc/profile.d/tomcat9.sh
    echo 'export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"' | tee -a /etc/profile.d/tomcat9.sh
    source /etc/profile.d/tomcat9.sh
else
    echo "Las variables de entorno ya están configuradas."
fi

echo "Proceso 14 de 16: Configurando usuarios de Tomcat..."
tee /var/lib/tomcat9/conf/tomcat-users.xml > /dev/null <<EOL
<tomcat-users>
  <role rolename="manager-gui"/>
  <user username="manager" password="your_password" roles="manager-gui"/>
  <role rolename="admin-gui"/>
  <user username="admin" password="your_password" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOL

echo "Proceso 15 de 16: Eliminando la etiqueta Valve en context.xml si existe..."
sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/d' /var/lib/tomcat9/webapps/manager/META-INF/context.xml

echo "Proceso 16 de 16: Creando el archivo de servicio para Tomcat..."
tee /etc/systemd/system/tomcat.service > /dev/null <<EOL
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

echo "Proceso 17 de 16: Recargando los archivos de servicio del sistema y habilitando el servicio Tomcat..."
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

echo "Verificando el estado del servicio Tomcat..."
systemctl status tomcat
