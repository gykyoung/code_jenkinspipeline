
FROM openjdk:8-jdk-alpine
COPY target/spring-petclinic-2.4.2.jar code.jar
VOLUME /tmp
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
CMD ["java", "-jar", "code.jar"]
