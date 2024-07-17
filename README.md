<p style="text-align: center;">
  <img src="Extras/Imagenes/logo.jpg" alt="Logo">
</p>

<center>

# Documento obligatorio-ORT-FI-69430-DevOps

</center>

<center>

**Integrantes:**

***Javier Bahar***

***Juan Mautone***

</center>

## Presentación del problema

Durante la transformación digital de una empresa líder en retail, surgió
un desafío que reveló una brecha significativa en la comunicación y
comprensión entre los equipos de desarrollo y operaciones. El
lanzamiento de una nueva aplicación, diseñada para mejorar la
experiencia de compra de los clientes, mostró errores recurrentes y
caídas del sistema, afectando la experiencia del usuario y la reputación
de la empresa. Este problema no era solo técnico, sino también cultural
y organizativo, ya que la separación entre el equipo de desarrollo,
enfocado en la rapidez y la innovación, y el equipo de operaciones,
centrado en la estabilidad, creó deficiencias en la responsabilidad
compartida y la comunicación efectiva.

## Propuesta

La dirección ejecutiva de la compañía intervino para abordar las causas
fundamentales del problema, reconociendo la necesidad de un cambio
cultural profundo. Se solicitó al equipo de proyecto un plan de acción
detallado que no solo aborde las ineficiencias operativas evidentes,
sino que también fomente un ambiente de colaboración, transparencia y
aprendizaje continuo. Este plan incluye estrategias específicas para
mejorar la comunicación y la colaboración entre los equipos de
desarrollo y operaciones, identificar y eliminar barreras que impidan la
eficacia de los flujos de trabajo integrados, y establecer prácticas que
promuevan una comprensión mutua de los desafíos y objetivos compartidos.

## Objetivos generales y específicos

El objetivo general de esta iniciativa es superar los obstáculos
actuales y establecer una base para la agilidad y resiliencia operativa
a largo plazo, asegurando así la competitividad de la empresa en el
mercado. Los objetivos específicos incluyen: mejorar la comunicación y
colaboración entre los equipos de desarrollo y operaciones, fomentar una
cultura de responsabilidad compartida, identificar y eliminar barreras
operativas, y promover una comprensión mutua de los desafíos y objetivos
comunes. A través de estos esfuerzos, se espera que la empresa no solo
resuelva los problemas actuales, sino que también mejore su capacidad
para adaptarse y prosperar en el futuro.

## Estrategia de ramas 
### Repositorios de Desarrollo (Gitflow)

<p style="text-align: center;">
  <img src="Extras/Imagenes/CICD/Diagramas-flujos-integracion/Diagrama-Desarrollo.png" alt="Diagrama de flujo">
</p>

En estos repositorios almacenamos todo lo relacionado al desarrollo de los microservicios, en nuestro caso tenemos 1 repositorio por microservicio de BE (4 en total) y 1 para el aplicativo de FE.

Para estos repositorios decidimos ir por la estrategia **"GitFlow"**, ya que nos permite trabajar en ramas dedicadas para características o correciones en paralelo y podemos mantener multiples ambientes para testeo.
Mantenemos 3 ramas estables (Main, Staging, Develop) y ramas temporales en caso de que se desarrollen nuevas features o haya posibles bugfixes/hotfixes.

### Repositorio de DevOps (Trunk Based)

<p style="text-align: center;">
  <img src="Extras/Imagenes/CICD/Diagramas-flujos-integracion/Diagrama-DevOps.png" alt="Diagrama de flujo">
</p>

En este repositorio almacenamos todo lo relacionado a documentación relevante, infrastructura como codigo e imagenes relacionadas al CI/CD.

Para este repositorio decidimos adoptar el modelo **"Trunk Based"**, debido a la naturaleza de la documentación que se encuentra en constante cambio y favorece la integración continua que trabajamos basandonos en una sola rama "Main". 
Manejamos "Feature branches" para las distintas partes agregadas de documentación e infrastructura como codigo.

## Tablero Kanban

<p style="text-align: center;">
  <img src="Extras/Imagenes/Kanban.png" alt="Kanban">
</p>

Para el manejo de tareas usamos el tablero "Kanban" que GitHub presta, este tiene el beneficio de ser trabajado con "Issues", los cuales pueden ser vinculados a nuevas ramas temporales. Al finalizar el trabajo en las mismas, se hace un pull request y se espera a la aprobación del otro, esto provoca que el estado del issue asociado a la rama cambie a finalizado.

## Proceso de CI/CD  

### Herramientas utilizadas

A continuación damos una explicación breve de cada herramienta usada tanto para el aplicativo de FE como los microservicios de BE.

- **GitHub**: Para alojar y versionar nuestro código en la nube, facilitando la colaboración y el control de cambios en el desarrollo.
- **GitHub Actions**: Para automizar flujos de trabajo y para desencadenar la Pipeline de CI/CD empleada.
- **SonarCloud**: Para analizar posibles vulnerabilidades en el codigo de los aplicativos.
- **Docker**: Para la creación y mantenimiento de imágenes de los microservicios de backend.
- **Maven**: Para la gestión de dependencias y la automatización de procesos de building en los microservicios de backend que usan Java.
- **Node**: Para compilar el aplicativo de frontend en JavaScript.
- **Postman**: Para testear el funcionamiento de las APIs de los microservicios de backend.
- **Newman**: Para ejecutar colecciones de Postman desde la línea de comandos desde un workflow file.
- **AWS Academy Learner Lab**: Para el uso y mantenimiento de recursos que otorga AWS.
- **Visual Studio Code**: Para desarrollo de forma local y gestión de recursos de software necesarios. 
- **Terraform**: Para definir y programar la infrastructura como codigo utilizada.
- **AWS CLI**: Para gestionar nuestros servicios de AWS por línea de comandos.
- **Elastic Container Repository (ECR)**: Para el almacenaje de imágenes Docker de los microservicios de backend.
- **Elastic Container Service (ECS)**: Como orquestador de contenedores Docker, manejando el escalado y la disponibilidad de nuestras aplicaciones.
- **API GW**: Para crear APIs y enrutar solicitudes al ALB mediante internet.
- **S3 Buckets**: Para el almacenamiento del código del aplicativo de frontend.

## IaC - Terraform 

Toda la infrastructura es desplegada como IaC en Terraform.
La misma está fragmentada por modulos y se diferencia su despliegue por workspaces.

Estructura de directorios utilizada:

```
terraform/
├── modules/
│   ├── ecr/
│   │   ├── ecr.tf
│   │   └── outputs.tf
│   ├── ecs/
│   │   ├── main.tf
│   │   └── variables.tf
│   └── s3_buckets/
│       ├── main.tf
│       └── outputs.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── README.md
└── variables.tf
```

A continuación enlistaremos la infrastructura desplegada por workspace: <br/>

### Workspace "s3_buckets_workspace":
- 1 S3 Bucket para el aplicativo de frontend con configuraciones de policies y acceso publico.

### Workspace "ecr_workspace":
- 1 ECR Repository para el almacenamiento de imagenes de los microservicios de backend.

### Workspace "ecs_env_workspace":
Networking:
- 1 VPC con 2 zonas de disponibilidad (us-east-1a - us-east-1b)
- 1 Cluster
- 4 Services (1 por microservicio)
- 4 Tasks definition (1 por Service)
- 1 ALB para distribuir la solicitud a la instancia del endpoint indicado.
- 1 API GW para enrutar la solicitud al load balancer y para poder comunicarse por internet.

Al estar manejando 3 ambientes, se hizo 1 workspace para cada ambiente estable, por lo que la palabra "env" es reemplazada por "dev", "stg" o "prod". <br/>

## Workflows para el desarrollo BE y FE
A continuación mostramos la estructura de directorios utilizada para los flujos de backend y frontend de CI/CD:
```
Extras/
Workflows
├── BE
│   ├── orders-service
│   │   ├── ci_cd_pipeline.yml
│   │   ├── workflow-dev.yml
│   │   ├── workflow-prod.yml
│   │   └── workflow-stage.yml
│   ├── payments-service
│   │   ├── ci_cd_pipeline.yml
│   │   ├── workflow-dev.yml
│   │   ├── workflow-prod.yml
│   │   └── workflow-stage.yml
│   ├── products-service
│   │   ├── ci_cd_pipeline.yml
│   │   ├── workflow-dev.yml
│   │   ├── workflow-prod.yml
│   │   └── workflow-stage.yml
│   └── shipping-service
│       ├── ci_cd_pipeline.yml
│       ├── workflow-dev.yml
│       ├── workflow-prod.yml
│       └── workflow-stage.yml
└── FE
    └── vue-app
        ├── scripts
        │   ├── build.sh
        │   └── deploy.sh
        └── workflows
            ├── ci_cd_pipeline.yml
            ├── workflow-dev.yml
            ├── workflow-prod.yml
            └── workflow-stage.yml
```


## Propuesta de CI/CD para los microservicios BE

<p style="text-align: center;">
  <img src="Extras/Imagenes/CICD/Diagramas-CICD/DiagramaBE.png" alt="Diagrama de CICD">
</p>

## CI (Integración Continua) para los microservicios
### GitHub Repository
Los desarrolladores realizan commits y pushes de código al repositorio de GitHub.

### GitHub Actions
Se activa un workflow en GitHub Actions cuando hay un push en el repositorio. GitHub Actions ejecuta una serie de pasos definidos en un archivo de configuración.

### SonarCloud 
SonarCloud realiza análisis estático y dinámico del código.
Evalúa la calidad del código, buscando errores, vulnerabilidades y problemas de mantenimiento.

#### Analisis en SonarCloud 
A continuación, se presentan los resultados obtenidos durante en análisis de código estático dentro de la rama main, de todos los repositorios que alojan los microservicios. 

> Aclaración: El análisis se realiza dentro de todas las ramas estables de los repositorios, es decir, en las ramas main, staging y develop. Pero a continuación mostraremos únicamente el analisis de la rama main.

#### Requisitos de calidad de código

Para el análisis de calidad de código utilizamos la configuracion que incluye SonarCloud por defecto, se trata de "Sonar Way".

#### Orders service

Para el microservicio "orders", el resultado fue "Failed". Esto quiere decir que no cumple con los requisitos de calidad definidos por SonarCloud. Cuando un análisis falla, puede ser que el código introducido tiene vulnerabilidades críticas de seguridad, malas prácticas de programación, código duplicado en exceso, falta de cobertura de pruebas, entre otros. 

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-be/orders-service1.png" alt="SonarCloud orders service">
</p>

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-be/orders-service2.png" alt="SonarCloud orders service">
</p>

#### Payments service

Para el microservicio de "payments", el resultado pasó los estándares de cálidad.

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-be/payments-service1.png" alt="SonarCloud payments service">
</p>

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-be/payments-service2.png" alt="SonarCloud payments service">
</p>

#### Products service

Para el microservicio de "products", el resultado pasó los estándares de cálidad.

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-be/products-service1.png" alt="SonarCloud products service">
</p>

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-be/products-service2.png" alt="SonarCloud products service">
</p>

#### Shipping service

Para el microservicio de "shipping", el resultado pasó los estándares de cálidad.

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-be/shipping-service1.png" alt="SonarCloud shipping service">
</p>

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-be/shipping-service1.png" alt="SonarCloud shipping service">
</p>

#### Build del microservicio
El proceso de build utiliza Maven para compilar el código fuente del microservicio, asegurando que todas las dependencias se resuelvan. Además, se ejecutan pruebas para verificar la funcionalidad del servicio antes de empaquetarlo en una imagen Docker.

### Testing en Postman (Newman)
Se ejecutan pruebas funcionales usando Postman Collections a través de Newman, el cual permite la automatización de pruebas de API, asegurando que los servicios funcionen correctamente. El fin de estas pruebas es reducir la posibilidad de introducir errores al código, y que todo funcione como se espera. 

Las siguientes imágenes mostrarán ejemplos de como se visualiza un proceso correcto de testing para todos los microservicios.

Las colecciones de Postman que se utilizaron para el testing de los microservicios se encuentra en el siguiente directorio:

```
Extras/
Testing/
└── BE/
    └── Postman-Collection/
        ├── orders.postman_collection.json
        ├── payments.postman_collection.json
        ├── products.postman_collection.json
        └── shipping.postman_collection.json
```

## Ejemplo de resultados correctos
### Orders service 

<p style="text-align: center;">
  <img src="Extras/Imagenes/Testing-de-be/testing-correcto-orders-service.png" alt="Testing correcto payments service">
</p>

### Payments service 

<p style="text-align: center;">
  <img src="Extras/Imagenes/Testing-de-be/testing-correcto-payments-service.png" alt="Testing correcto payments service">
</p>

### Products service 

<p style="text-align: center;">
  <img src="Extras/Imagenes/Testing-de-be/testing-correcto-products-service.png" alt="Testing correcto payments service">
</p>

### Shipping service 

<p style="text-align: center;">
  <img src="Extras/Imagenes/Testing-de-be/testing-correcto-shipping-service.png" alt="Testing correcto payments service">
</p>

<p style="text-align: center;">
  <img src="Extras/Imagenes/testing-correcto-alb.jpeg" alt="">
</p>

## CD (Entrega Continua) para los microservicios
### Docker 
El proyecto se empaqueta en una imagen de Docker.
La imagen contiene todo lo necesario para ejecutar la aplicación, como el código, las dependencias y el entorno.

### ECR (Elastic Container Registry): 
La imagen de Docker se sube al repositorio de ECR en AWS, el cual gestiona el almacenamiento y la recuperación de imágenes de contenedores.

#### Push image ECR 

Una vez empaquetado el microservicio en una imagen de Docker. La imagen se sube al repositorio de ECR en AWS, el cual gestiona el almacenamiento y la recuperación de imágenes de contenedores.

Las imagen alojadas en este contenedor de imagenes, estan diferenciadas por sus etiquetas, el cual lleva el nombre del microservicio acompañado del nombre de la rama estable, que puede ser "prod" por production, "stg" por staging y "dev" por develop.

Ejemplo: orders-service-develop, orders-service-stg, orders-service-prod

En la imagen a continuación se ven todos los contenedores registrados para el ambiente develop:

<p style="text-align: center;">
  <img src="Extras/Imagenes/CICD/BE/ecr-repository.png" alt="">
</p>

> Dato: Los nuevos contenedores que se registran obtienen la nueva etiqueta y los antiguos la pierden.

### Deploy en ECS (Elastic Container Services)
Para los servicios de backend se decidió usar Elastic Container Services, los mismos fueron desplegados en base a los ambientes que tenemos los cuales son dev, staging y prod. <br/>
Las imagenes que anteriormente fueron subidas al repositorio de ECR, son luego actualizadas por el workflow de CI/CD en el task definition y en la revision de cada service. <br/>
Luego de esto, el ALB se ocupa de verificar que cada task funcione correctamente con un health check, y de ser así despliega un target.

### Servicio serverless - API Gateway

El load balancer al ser interno, requiere de un API GW para poder conectarse a internet, por lo que agrega otra capa de seguridad.

## Propuesta de CI/CD para aplicación FE

<p style="text-align: center;">
  <img src="Extras/Imagenes/CICD/Diagramas-CICD/DiagramaFE.png" alt="Diagrama de CICD">
</p>

## CI (Integración Continua) para la aplicación Frontend
### GitHub Repository
Los desarrolladores realizan commits y pushes de código al repositorio de GitHub.

### GitHub Actions 
Se activa un workflow en GitHub Actions cuando hay un push en el repositorio. GitHub Actions ejecuta una serie de pasos definidos en un archivo de configuración.

### SonarCloud 

Para la aplicación frontend nuevamente utilizamos SonarCloud para el análisis de código estático. Tambien se utilzó la configuración por defecto brindada por SonarCloud.

#### Resultados del analisis de codigo

Los resultados obtenidos son los siguientes:

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-fe/vue-app1.png" alt="SonarCloud aplicación frontend">
</p>

<p style="text-align: center;">
  <img src="Extras/Imagenes/Sonarcloud/Informes-de-fe/vue-app2.png" alt="SonarCloud aplicación frontend">
</p>

### Build (Node.js & npm)

Es la etapa de instalación de dependencias y posterior build de la aplicación. El proyecto se compila utilizando Node.js y npm. Antes de finalizar, se sube el compilado a un artifact de GitHub, el cual luego queda asociado al workflow y permite ser descargado para poder tener un control de las versiones.

A su vez, este artifact es utilzado para el proceso de deploy en el S3 Bucket.

Creación del artefacto en ejecución:

<p style="text-align: center;">
  <img src="Extras/Imagenes/CICD/FE/upload-build-artifacts.png" alt="">
</p>

Como se visualiza el artefacto generado:

<p style="text-align: center;">
  <img src="Extras/Imagenes/CICD/FE/build-artifacts.png" alt="">
</p>

## CD (Entrega Continua) para la aplicación Frontend

### Download Build Artifacts
Se descargan los artefactos de construcción desde GitHub Artifacts.

### Amazon S3 
La aplicación frontend, luego de las etapas de análisis de código estático e instalación de dependencias y build del aplicativo, es desplegada en un S3 Bucket. Cada rama estable tiene su propio ambiente y su propio S3 Bucket (3 en total, 1 para main, 1 para staging y otro para develop).



