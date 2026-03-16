pipeline {
    agent any

    tools {
        maven 'M3'
    }

    stages {

        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan .', odcInstallation: 'default'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

    }
}

// pipeline {
//     agent any
    
//     tools {
//         maven 'M3'  
//         jdk 'OpenJDK 11' 
//     }
    
//     stages {
//         stage('Checkout') {
//             steps {
//             }
//         }
        
//         stage('Build') {
//             steps {
//             }
//         }
        
//         stage('Dependency Scanning Parallel') {
//             parallel {
              
//             }
//         }
//         stage('Publish Dependency-Check Results') {
//             steps {
               
//             }
//         }
//         stage('Unit Tests') {
//             steps {
//             }
//         }
        
//         stage('Integration Tests') {
//             steps {
//             }
//         }
        
//         stage('Code Coverage') {
//             steps {
             
//             }
//         }
        
//         stage('SAST - SonarQube') {
//             steps {
//             }
//         }
        
//         stage('Package') {
//             steps {
//             }
//         }
//     }
    
//     post {
//         success {
//             echo 'Pipeline completed successfully!'
//         }
//         failure {
//             echo 'Pipeline failed!'
//         }
//     }
// }



