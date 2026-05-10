FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY springboot.jar springboot.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","springboot.jar"]
