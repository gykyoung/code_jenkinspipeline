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
		sh 'pwd'
		sh 'sshpass -p k8snew ssh k8snew@192.168.56.101 sh deploy.sh code@${BUILD_NUMBER}'
                //kubernetesDeploy configs: "code.yaml", kubeconfigId: 'kubernetes-jenkins'
		//sh "kubectl --kubeconfig=/root/.jenkins/.kube/config rollout restart deployment/code-sample-deployment"
		//sh "kubectl apply -f code.yaml"
		echo "deploy Success!!!!!!!!!!!!!!!!!!!!!"
		}
            }
        }
    }
//}
