1. Descripción del proyecto

MarketMove App es una aplicación móvil diseñada para pequeños comercios. Su objetivo es permitir al usuario registrar ventas diarias, gastos del negocio, productos en stock y consultar un balance general.
El proyecto forma parte de una práctica académica enfocada en el desarrollo de aplicaciones multiplataforma y documentación técnica.

La aplicación se está desarrollando con Flutter y utiliza Supabase como sistema de autenticación y base de datos.

2. Desarrollador

Rubén Vega
Proyecto individual

3. Funcionalidades principales

Registro e inicio de sesión
Añadir ventas del día
Añadir gastos
Gestión de productos y stock
Panel de resumen con balance económico
Conexión con base de datos Supabase

4. Tecnologías utilizadas

Flutter 3.x
Dart
Supabase (Autenticación y Base de Datos)
VS Code
Git y GitHub

5. Arquitectura del proyecto

El proyecto sigue una estructura modular basada en funcionalidades:

lib/
  src/
    features/
      auth/
      ventas/
      gastos/
      productos/
      resumen/
    shared/
      widgets/
      models/
      services/
      providers/
assets/
  images/
  icons/


Cada módulo contiene la lógica y las pantallas correspondientes.
El directorio shared almacena componentes reutilizables.

6. Instalación y ejecución

Clonar el repositorio:

git clone https://github.com/GlerionSH/marketmove_app.git


Entrar en la carpeta del proyecto:

cd marketmove_app


Instalar dependencias:

flutter pub get


Configurar Supabase en los servicios correspondientes.
Se deben añadir la URL del proyecto y la clave pública (anon key).

Ejecutar la aplicación:

flutter run

7. Estado actual del proyecto

Estructura de carpetas configurada
Pantallas principales maquetadas
Navegación básica implementada
Integración con Supabase en proceso
MVP en fase de desarrollo

8. Documentación del proyecto

Los documentos oficiales del proyecto se encuentran en la carpeta docs:

Presupuesto del proyecto (PDF)
Informe semanal de trabajo (PDF)

9. Licencia

Proyecto académico para prácticas de Desarrollo de Aplicaciones Multiplataforma.
No destinado a uso comercial.
