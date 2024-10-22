# Proyecto de Scripts de Instalación y Configuración

Este proyecto contiene scripts para la instalación y configuración de diversos servicios y aplicaciones en sistemas Debian. Actualmente, incluye un script para la instalación y configuración de Apache Tomcat 9 con Java 11.

## Contenido

- install_tomcat_java11_v1.sh
- sudo_install_tomcat_java11_v1.sh
- Cómo usar los scripts
- Agregar nuevos scripts

### install_tomcat_java11.sh

Este script automatiza la instalación y configuración de Apache Tomcat 9 en un sistema Debian. Incluye la configuración de Tomcat como un servicio del sistema para que se inicie automáticamente al arrancar el sistema.

#### Instrucciones de uso

1. **Descargar el script**:
   ```bash
   wget https://davidhdezlemus.github.io/paginaFicheros/src/files/install_tomcat_java11_v1.sh
   ```

2. **Dar permisos de ejecución al script**:
   ```bash
   chmod +x install_tomcat_java11_v1.sh
   ```

3. **Ejecutar el script**:
   ```bash
   ./install_tomcat_java11_v1.sh
   ```

### Cómo usar los scripts

Para usar cualquiera de los scripts disponibles en este proyecto, sigue los pasos generales a continuación:

1. **Descargar el script** desde la URL proporcionada.
2. **Dar permisos de ejecución** al script usando `chmod +x nombre-del-script.sh`.
3. **Ejecutar el script** con `./nombre-del-script.sh`.

## Licencia

Este proyecto está licenciado bajo la MIT License.
