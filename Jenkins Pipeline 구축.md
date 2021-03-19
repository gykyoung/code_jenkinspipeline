# Jenkins Pipeline 구축

>  **<u>목표 : 처음부터 시작하여 Pipeline 구축 -> 이미지 생성 -> 배포할 수 있도록 구성</u>**



## **jenkins pipline 구축 및 docker image 생성 그리고 pod 배포**

### 구성도

<img width="666" alt="스크린샷 2021-03-16 오후 12 19 47" src="https://user-images.githubusercontent.com/73063032/111251166-0983b980-8652-11eb-83c8-22964e7084cd.png">





### 준비 사항

Master 

- memory : 4098MB
- Cpu : 2

Node01

- memory : 4098MB
- Cpu : 2

Github (일반 GitHub : https://github.com/gykyoung/)

- 배포할 소스 Repository
- Jenkins Pipeline에 필요한 Repository

Docker-hub

- 계정



---



### 1. Jenkins 띄우기

> Master node에 jenkins를 띄운다.

#### docker-compose.yaml

````yaml
version: "3"

services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: "jenkins_docker"
    restart: always
    ports:
      - "8080:8080"
      - "50000:50000"
    expose:
      - "8080"
      - "50000"
    volumes:
      - "./jenkins_home:/var/jenkins_home"
      - "/var/run/docker.sock:/var/run/docker.sock"
    environment:
      TZ: "Asia/Seoul"
````



#### Dockerfile

````dockerfile
FROM jenkins/jenkins:latest

# Changing the user to root
USER root
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# installing chrome driver
RUN apt-get update && apt-get -qq -y install curl

# Update the package list and install chrome
RUN apt-get update -y

# open jdk 13
# RUN curl -O https://download.java.net/java/GA/jdk13/5b8a42f3905b406298b72d750b6919f6/33/GPL/openjdk-13_linux-x64_bin.tar.gz
# RUN tar xvf openjdk-13_linux-x64_bin.tar.gz
#RUN mv /opt/java/openjdk /opt/java/openjdk_backup
#RUN mv jdk-13 /opt/java/openjdk

# Install maven
RUN apt-get -y update && apt-get install -y maven

# Install gradle
RUN apt-get -y update && apt-get install -y gradle

COPY docker_install.sh /docker_install.sh
RUN chmod +x /docker_install.sh
RUN /docker_install.sh
````



#### docker_install.sh

````shell
apt-get update && \
apt-get -y install apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     zip \
     unzip \
     software-properties-common && \
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable" && \
apt-get update && \
apt-get -y install docker-ce
````



#### => jenkins 접속 : <u>해당 서버 IP:8080</u>

---



### 2. Jenkins 플러그인 설치

````
Azure 
Docker
CloudBees 
Publish Over SSH
SonarQubeScanner 
Kubernetes
gitlab(or github)
````



---



### 3. Github 구성

- 소스 코드 Repository
- Jenkins Pipeline Repository
  - **jenkinsfile**
  - **Dockerfile**
  - 등등 ...



---



### 4. Credential 발급

> **<u>jenkins와 git</u> 연동을 위해 사용**

https://goddaehee.tistory.com/258



---



### 임시 테스트

#### jenkinsfile 작성

<img width="1110" alt="스크린샷 2021-03-16 오후 3 57 59" src="https://user-images.githubusercontent.com/73063032/111268317-760db100-8670-11eb-9ab2-31be4e60de19.png" style="zoom: 67%;" >



#### Jenkins pipeline 구성

<img width="1358" alt="스크린샷 2021-03-16 오후 3 59 57" src="https://user-images.githubusercontent.com/73063032/111268495-b4a36b80-8670-11eb-8306-0ca79dae502e.png">



**=>> 빌드 성공**

<img src="https://user-images.githubusercontent.com/73063032/111268667-e7e5fa80-8670-11eb-9563-a0d3a6701022.png" alt="스크린샷 2021-03-16 오후 4 01 39" style="zoom: 50%;" />



---



### 5. 실제 소스 배포



#### 5.1 jenkins & docker-hub CredentialID 생성 (<u>CredentialID : docker-hub</u> 로 설정)

> Username, password에는 docker-hub 계정 및 password를 입력

참고 : https://teichae.tistory.com/entry/Jenkins-Pipeline%EC%9D%84-%EC%9D%B4%EC%9A%A9%ED%95%9C-Docker-Image-Push

<img width="945" alt="스크린샷 2021-03-16 오후 7 20 48" src="https://user-images.githubusercontent.com/73063032/111293574-c266ea00-868c-11eb-9fd1-6a6b52fc0121.png" style="zoom:67%;" >



#### 5.2 jenkinsPipeline 및 Dockerfile 구성

- jenkinsfile

````yaml
pipeline {
    agent any
    
    stages {
    
        stage("step1.checkout") {
            steps {
                echo "checkout!!!!!!!!!!!!!!!!!!!!!"
                git branch: 'main', url: 'https://github.com/gykyoung/code.git'
                echo "checkout Success!!!!!!!!!!!!!!!!!!!!!"
            }
        }
    
        stage("step2.build") {
            steps {
                echo "build!!!!!!!!!!!!!!!!!!!!!"
                sh 'pwd'
                sh 'mvn clean package' 
                //sh 'mvn -f automanWebapp/pom.xml clean install -P release'
              	//archive '**/target/*.war'
            }
        }
    
        stage("step3.docker images") {
            steps {
                echo "docker images!!!!!!!!!!!!!!!!!!!!!"
                git branch: 'main', url: 'https://github.com/gykyoung/code_jenkinspipeline.git'
                script {
                    sh 'pwd'
                    dockerImage = docker.build("gykmegazone/code:$BUILD_NUMBER")
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub') {
                        dockerImage.push("${env.BUILD_NUMBER}")
                        dockerImage.push("latest")
                    }
                }
                echo "docker images Success!!!!!!!!!!!!!!!!!!!!!"
            }
        }
    
        stage("step4.deploy") {
            steps {
                echo "deploy!!!!!!!!!!!!!!!!!!!!!"
            }
        }
    }
}
````



- Dockerfile

````dockerfile
FROM openjdk:8-jdk-alpine
COPY target/spring-petclinic-2.4.2.jar code.jar
VOLUME /tmp
ENV port 8080
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
CMD ["java", "-jar", "code.jar"]
````



#### 5.3 Docker-hub Image Push 확인

<img width="1311" alt="스크린샷 2021-03-16 오후 7 10 02" src="https://user-images.githubusercontent.com/73063032/111293588-c5fa7100-868c-11eb-8555-0a42bc183116.png" style="zoom:67%;" >



#### 5.4 생성된 이미지로 POD 띄우기

````yaml
apiVersion: v1
kind: Service
metadata:
  name: code-sample
  labels:
    app: code-sample
spec:
  selector:
    app: code-sample
  ports:
    - port: 8080
      protocol: TCP
  type: LoadBalancer
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: code-sample-ac
  labels:
    app: code-sample
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-sample-deployment
  labels:
    app: code-sample
spec:
  replicas: 1
  selector:
    matchLabels:
      app: code-sample
  template:
    metadata:
      labels:
        app: code-sample
    spec:
      serviceAccountName: code-sample-ac
      containers:
      - name: code-sample
        image: registry.hub.docker.com/gykmegazone/code:latest
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 500m
     #nodeSelector:
     #   nodeType: worker1
````





#### 띄워진 POD 확인

<img width="666" alt="스크린샷 2021-03-16 오후 7 25 42" src="https://user-images.githubusercontent.com/73063032/111294264-7a949280-868d-11eb-9743-7e5751d8a993.png">

#### LB를 통해 해당 서비스가 node01에 배포되도록 설정 (node01에서 docker ps 명령어를 실행해보면 해당 container가 노출된다.)

<img width="1772" alt="스크린샷 2021-03-17 오후 1 49 17" src="https://user-images.githubusercontent.com/73063032/111416616-a1070c00-8727-11eb-9bf3-38ebfb349a3c.png">



#### 외부 노출

<img width="1350" alt="스크린샷 2021-03-16 오후 7 26 03" src="https://user-images.githubusercontent.com/73063032/111294251-76687500-868d-11eb-95ff-276d71c99202.png">





---



## 이어서 Webhook 및 자동배포 기능 추가



### 1. Webhook

> 소스 수정 후 Github에 소스를 push하면, Github에서 jenkins에 소스 수정 event를 발생시켜주고, Jenkins는 Github에서 소스를 내려 받아 Build 를 자동으로 Run하는 방법

참고 : https://kutar37.tistory.com/entry/Jenkins-Github-%EC%97%B0%EB%8F%99-%EC%9E%90%EB%8F%99%EB%B0%B0%ED%8F%AC-3

https://medium.com/hgmin/jenkins-github-webhook-3dc13efd2437

#### 1.1 본인의 GitHub 프로젝트 Settings >> Webhooks >> Add Webhook 클릭

<img width="1315" alt="스크린샷 2021-03-17 오전 10 45 03" src="https://user-images.githubusercontent.com/73063032/111402113-ee767f80-870d-11eb-9064-b31e1a520666.png" style="zoom: 50%;" >



#### 1.2  **Jenkins 주소/github-webhook/** 입력



##### 참고 : <u>jenkins 관리 -> 시스템 설정</u>에서 다음과 같이 설정한 후 webhook 진행

<img width="1377" alt="스크린샷 2021-03-17 오전 11 13 40" src="https://user-images.githubusercontent.com/73063032/111404298-dacd1800-8711-11eb-80ac-d913c61fe287.png">



<img width="830" alt="스크린샷 2021-03-17 오전 10 52 09" src="https://user-images.githubusercontent.com/73063032/111402635-e0752e80-870e-11eb-86b5-05603dcbe1ba.png" style="zoom:67%;" >



#### 1.3 **GitHub hook trigger for GITScm polling** 선택

<img width="1078" alt="스크린샷 2021-03-17 오전 11 15 17" src="https://user-images.githubusercontent.com/73063032/111404417-14058800-8712-11eb-9faa-b28c580dbf95.png">



#### 1.4 Push로 소스 수정 후 자동으로 Build 수행

####  1.4.1 Webhook 과정 중 error 발생 (<u>ngrok 사용하기</u>)

=> PUSH 하기전 ngrok 설정한 후 webhook 진행하기

참고 : https://m.blog.naver.com/snt2525/221287819314

https://velog.io/@kya754/ngrok-%EC%82%AC%EC%9A%A9%ED%95%98%EA%B8%B0



<img width="830" alt="스크린샷 2021-03-17 오전 11 29 56" src="https://user-images.githubusercontent.com/73063032/111405590-1d8fef80-8714-11eb-8aba-a263d4083f35.png">



##### Ngrok 설치 (<u>Jenkins Server가 설치된 위치</u>(VM : Master)에서 설치한다.)

````
$ sudo snap install ngrok
````



##### ngrok이 있는 위치에서 다음 명령어 실행 (/snap/bin/ngrok)

````
$ ./ngrok http 8080
````

<img width="597" alt="스크린샷 2021-03-17 오후 12 15 26" src="https://user-images.githubusercontent.com/73063032/111409537-795d7700-871a-11eb-869c-fc123f9ff493.png">



##### GitHub webhook URL 다음과 같이 수정

<img width="826" alt="스크린샷 2021-03-17 오후 12 16 05" src="https://user-images.githubusercontent.com/73063032/111409619-a578f800-871a-11eb-9be3-97c42f754e71.png" style="zoom:67%;" >



##### CODE PUSH를 날린다. (Webhook 동작)

=> webhook을 통해 성공적으로 image가 생성된 것을 확인할 수 있다.

- ngrok

<img src="https://user-images.githubusercontent.com/73063032/111415981-546f0100-8726-11eb-86b0-ee55b10aa565.png" alt="스크린샷 2021-03-17 오후 1 40 02" style="zoom: 50%;" />



- jenkins

<img src="https://user-images.githubusercontent.com/73063032/111416808-f7744a80-8727-11eb-990d-11647739961e.png" alt="스크린샷 2021-03-17 오후 1 51 58" style="zoom:50%;" />



- Docker-hub

<img width="735" alt="스크린샷 2021-03-17 오후 1 54 54" src="https://user-images.githubusercontent.com/73063032/111417042-66ea3a00-8728-11eb-8d9a-8c0196237e88.png" style="zoom: 67%;" >





### 2. 자동배포

=> Jenkins → Credentials → System에서 위와 같이 Kubernetes 관련 Credential 정보를 입력

#### 2.1 Kubernetes 관련 Credential 정보 (첫번째 방법 사용)

참고 : https://waspro.tistory.com/573

- 첫번째 Enter directly 방식은 Mater Node에 등록되어 있는 Kubernetes Credential (.kube/config) 내용을 그대로 넣어주는 방식 
- 그 밖에도 Jenkins Home에 kubeconfig를 넣어주거나 직접 Kubernetes Master Node로 부터 입력받는 방법들을 사용



#### 2.1.1 Master Node의 /home/k8snew/.kube 위치에 있는 config를 복사한 후 Jenkins → Credentials → System에서 위와 같이 Kubernetes 관련 Credential 정보를 입력

<img width="1324" alt="스크린샷 2021-03-17 오후 2 21 24" src="https://user-images.githubusercontent.com/73063032/111419043-1543ae80-872c-11eb-83d9-4e148cb7ecb8.png">



##### => 생성 완료

<img width="1054" alt="스크린샷 2021-03-17 오후 2 22 36" src="https://user-images.githubusercontent.com/73063032/111419131-3c01e500-872c-11eb-9f79-b0bc3bd8fdf5.png">



### Jenkinsfile

````yaml
stage("step4.deploy") {
            steps {
                echo "deploy!!!!!!!!!!!!!!!!!!!!!"
                kubernetesDeploy configs: "code.yaml", kubeconfigId: 'kubernetes-jenkins'
		            sh "kubectl --kubeconfig=/root/.jenkins/.kube/config rollout restart deployment/code-sample-deployment"
		            echo "deploy Success!!!!!!!!!!!!!!!!!!!!!"
		}
            }
````



#### ERROR 발생으로 자동 배포는 보류

참고 : https://prometheo.tistory.com/82

> 각각의 버전이 맞지 않아 생기는 문제로 생각됨

````
# 참고

Jenkins Version이 올라가며, EKS와 연동 시 플러그인 버전 차이로 인한 배포 실패가 발생할 수 있습니다.

이때, Manually하게

- jackson2-api-2.10.3.hpi

- kubernetes-cd-2.3.0.hpi

- snakeyaml-api.hpi

- azure-common-1.0.5.hpi
````

````
다운 그레이드 : Jackson 2 API 2.10.0, Kubernetes 1,21.3, Kubernetes 클라이언트 API 4,6.3-1, Kubernetes 지속적 배포 2.1.2, Kubernetes 자격 증명 0.5.0

ERROR: ERROR: Can't construct a java object for tag:yaml.org,2002:io.kubernetes.client.openapi.models.V1Service; exception=Class not found: io.kubernetes.client.openapi.models.V1Service
 in 'reader', line 1, column 1:
    apiVersion: v1
    ^

hudson.remoting.ProxyException: Can't construct a java object for tag:yaml.org,2002:io.kubernetes.client.openapi.models.V1Service; exception=Class not found: io.kubernetes.client.openapi.models.V1Service
 in 'reader', line 1, column 1:
    apiVersion: v1
    ^

	at org.yaml.snakeyaml.constructor.Constructor$ConstructYamlObject.construct(Constructor.java:335)
	at org.yaml.snakeyaml.constructor.BaseConstructor.constructObjectNoCheck(BaseConstructor.java:229)
	at org.yaml.snakeyaml.constructor.BaseConstructor.constructObject(BaseConstructor.java:219)
	at io.kubernetes.client.util.Yaml$CustomConstructor.constructObject(Yaml.java:337)
	at org.yaml.snakeyaml.constructor.BaseConstructor.constructDocument(BaseConstructor.java:173)
	at org.yaml.snakeyaml.constructor.BaseConstructor.getSingleData(BaseConstructor.java:157)
	at org.yaml.snakeyaml.Yaml.loadFromReader(Yaml.java:490)
	at org.yaml.snakeyaml.Yaml.loadAs(Yaml.java:456)
	at io.kubernetes.client.util.Yaml.loadAs(Yaml.java:224)
	at io.kubernetes.client.util.Yaml.modelMapper(Yaml.java:494)
	at io.kubernetes.client.util.Yaml.loadAll(Yaml.java:272)
	at com.microsoft.jenkins.kubernetes.wrapper.KubernetesClientWrapper.apply(KubernetesClientWrapper.java:236)
	at com.microsoft.jenkins.kubernetes.command.DeploymentCommand$DeploymentTask.doCall(DeploymentCommand.java:172)
	at com.microsoft.jenkins.kubernetes.command.DeploymentCommand$DeploymentTask.call(DeploymentCommand.java:124)
	at com.microsoft.jenkins.kubernetes.command.DeploymentCommand$DeploymentTask.call(DeploymentCommand.java:106)
	at hudson.FilePath.act(FilePath.java:1252)
	at com.microsoft.jenkins.kubernetes.command.DeploymentCommand.execute(DeploymentCommand.java:68)
	at com.microsoft.jenkins.kubernetes.command.DeploymentCommand.execute(DeploymentCommand.java:45)
	at com.microsoft.jenkins.azurecommons.command.CommandService.runCommand(CommandService.java:88)
	at com.microsoft.jenkins.azurecommons.command.CommandService.execute(CommandService.java:96)
	at com.microsoft.jenkins.azurecommons.command.CommandService.executeCommands(CommandService.java:75)
	at com.microsoft.jenkins.azurecommons.command.BaseCommandContext.executeCommands(BaseCommandContext.java:77)
	at com.microsoft.jenkins.kubernetes.KubernetesDeploy.perform(KubernetesDeploy.java:42)
	at com.microsoft.jenkins.azurecommons.command.SimpleBuildStepExecution.run(SimpleBuildStepExecution.java:54)
	at com.microsoft.jenkins.azurecommons.command.SimpleBuildStepExecution.run(SimpleBuildStepExecution.java:35)
	at org.jenkinsci.plugins.workflow.steps.SynchronousNonBlockingStepExecution.lambda$start$0(SynchronousNonBlockingStepExecution.java:47)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: hudson.remoting.ProxyException: org.yaml.snakeyaml.error.YAMLException: Class not found: io.kubernetes.client.openapi.models.V1Service
	at org.yaml.snakeyaml.constructor.Constructor.getClassForNode(Constructor.java:664)
	at org.yaml.snakeyaml.constructor.Constructor$ConstructYamlObject.getConstructor(Constructor.java:322)
	at org.yaml.snakeyaml.constructor.Constructor$ConstructYamlObject.construct(Constructor.java:331)
	... 30 more
````



## 자동 배포 과정 1

### Docker로 띄운 Jenkins안에 들어가 kubernetes를 설치하여 kubectl 명령어가 실행될 수 있도록 구성

#### 1. Jenkins container 들어가기

````
$ docker exec -it [container 이름,id] /bin/bash
````



#### 2. container안에 kubernetes 설치

````
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
````



### <u>=> kubectl 명령어 실행이 안됌. 다른 방향으로 접근</u>



## 자동 배포 과정 2

### jenkins container안에 ssh, sshpass를 설치하여 jenkins container -> hostOS(VM) 접속하여 kubectl 명령어 실행하기



#### Jenkins plugin 설치

````
SSH 관련 plugin 설치
SSH Agent plugin ..
````



#### jenkins container 접속

````
k8snew@master:~$ docker exec -it [jenkins container id] /bin/bash
````



#### jenkins container에 다음을 설치

참고 : https://phoenixnap.com/kb/how-to-ssh-into-docker-container

````
root@786b60f48f15:/# apt-get install ssh
root@786b60f48f15:/# apt-get install sshpass
````



#### jenkinsfile

참고 : http://www.netkiller.cn/linux/project/jenkins/Jenkinsfile.html

https://github.com/jenkinsci/ssh-steps-plugin#sshcommand

https://unix.stackexchange.com/questions/459923/multiple-commands-in-sshpass

> sh 'sshpass -p k8snew ssh k8snew@192.168.56.101 kubectl apply -f code.yaml' 추가

````
stage("step4.deploy") {
    steps {
    echo "deploy!!!!!!!!!!!!!!!!!!!!!"
		sh 'pwd'
		sh 'sshpass -p k8snew ssh k8snew@192.168.56.101 kubectl apply -f code.yaml'
    //kubernetesDeploy configs: "code.yaml", kubeconfigId: 'kubernetes-jenkins'
		//sh "kubectl --kubeconfig=/root/.jenkins/.kube/config rollout restart deployment/code-sample-deployment"
		//sh "kubectl apply -f code.yaml"
		echo "deploy Success!!!!!!!!!!!!!!!!!!!!!"
		}
}
````



#### jenkins 빌드

=> 성공한 것을 확인할 수 있다.

````
deploy!!!!!!!!!!!!!!!!!!!!!
[Pipeline] sh
+ pwd
/var/jenkins_home/workspace/jenkinspipeline_code
[Pipeline] sh
+ sshpass -p k8snew ssh k8snew@192.168.56.101 kubectl apply -f code.yaml
service/code-sample created
serviceaccount/code-sample-ac created
deployment.apps/code-sample-deployment created
[Pipeline] echo
deploy Success!!!!!!!!!!!!!!!!!!!!!
````



### 보완할 점

1. Sshpass multi command가 안돼는지 확인이 필요
2. Shell script를 작성하여 배포해보기
3. 빌드 후 조치를 이용하여 배포해보기











참고

https://goddaehee.tistory.com/260?category=399178

https://gwonsungjun.github.io/articles/2019-04/jenkins_tutorial_5

https://teichae.tistory.com/entry/Jenkins-Pipeline%EC%9D%84-%EC%9D%B4%EC%9A%A9%ED%95%9C-Docker-Image-Build

https://www.howtodo.cloud/devops/docker/2019/05/16/devops-application.html

https://teichae.tistory.com/entry/Jenkins-Pipeline%EC%9D%84-%EC%9D%B4%EC%9A%A9%ED%95%9C-Docker-Image-Push



https://kutar37.tistory.com/entry/Jenkins-Github-%EC%97%B0%EB%8F%99-%EC%9E%90%EB%8F%99%EB%B0%B0%ED%8F%AC-3

https://medium.com/hgmin/jenkins-github-webhook-3dc13efd2437













































