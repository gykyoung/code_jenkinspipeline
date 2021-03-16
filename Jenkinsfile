pipeline {
    agent none
    stages{
        stage('Parallel Test') {
            parallel { 
                stage('Build-test-1') {
                    steps{ build 'Build-test-1' }
                }
                stage('Build-test-2') {
                    steps{ build 'Build-test-2' }
                }
                stage('Build-test-3') {
                    steps{ build 'Build-test-3' }
                }
            }
        }
        stage('Build-test-4') {
            steps{
                build 'Build-test-4'
            }
        }
    }
}
