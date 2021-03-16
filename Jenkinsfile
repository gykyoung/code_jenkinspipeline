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
                    dockerImage = docker.build("yk/code:$BUILD_NUMBER")
                    docker.withRegistry('https://registry.hub.docker.com', 'gykmegazone') #업로드할 레지스트리 정보, Jenkins Credentials ID {
                    dockerImage.push("${env.BUILD_NUMBER}") #image에 빌드번호를 태그로 붙인 후 Push
                    dockerImage.push("latest") #image에 latest를 태그로 붙인 후 Push
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
