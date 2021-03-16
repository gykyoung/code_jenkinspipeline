
FROM openjdk:8-jdk-alpine
COPY target/*.jar code.jar
VOLUME /tmp
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
CMD ["java", "-jar", "code.jar"]
