#!/bin/bash

# Actualizar los paquetes del sistema
sudo apt update

# Agregar el repositorio de Debian unstable
echo "deb http://deb.debian.org/debian unstable main non-free contrib" | sudo tee /etc/apt/sources.list.d/unstable.list

# Actualizar los paquetes del sistema nuevamente
sudo apt update

# Instalar Java 11
sudo apt install -y openjdk-11-jdk

# Verificar la instalación de Java
java -version

# Descargar Apache Tomcat 9
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.96/bin/apache-tomcat-9.0.96.tar.gz

# Extraer el archivo descargado
tar xzf apache-tomcat-9.0.96.tar.gz

# Mover el directorio de Tomcat a /var/lib/tomcat9
sudo mv apache-tomcat-9.0.96 /var/lib/tomcat9

# Configurar permisos
sudo chown -R $USER:$USER /var/lib/tomcat9
sudo chmod +x /var/lib/tomcat9/bin/*.sh

# Configurar variables de entorno
echo 'export CATALINA_HOME="/var/lib/tomcat9"' | sudo tee /etc/profile.d/tomcat9.sh
echo 'export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"' | sudo tee -a /etc/profile.d/tomcat9.sh
source /etc/profile.d/tomcat9.sh

# Configurar usuarios de Tomcat
sudo tee /var/lib/tomcat9/conf/tomcat-users.xml > /dev/null <<EOL
<tomcat-users>
  <role rolename="manager-gui"/>
  <user username="manager" password="your_password" roles="manager-gui"/>
  <role rolename="admin-gui"/>
  <user username="admin" password="your_password" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOL

# Eliminar la etiqueta Valve en context.xml
sudo sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/d' /var/lib/tomcat9/webapps/manager/META-INF/context.xml

# Iniciar Tomcat
/var/lib/tomcat9/bin/startup.sh

# Configurar crontab (opcional, si necesitas alguna tarea programada)
# crontab -e

echo "Instalación y configuración de Tomcat 9 completada."
