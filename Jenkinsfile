pipeline {
    agent any
    
    environment{
        dockerImage = ''
    }
    
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
                dockerImage = docker.build("yk/code:$BUILD_NUMBER")
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
