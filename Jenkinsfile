pipeline {
    agent any
    
    tools {
        maven 'M3'
        jdk 'OpenJDK 17'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Checkout stage completed successfully!'
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean compile'
                echo 'Build stage completed successfully!'
            }
        }
    }
}









// pipeline {
//     agent any

//     tools {
//         maven 'M3'
//     }

//     stages {

//         stage('Checkout') {
//             steps {
//                 checkout scm
//             }
//         }

//         stage('Build') {
//             steps {
//                 sh 'mvn clean compile'
//             }
//         }

//         stage('Unit Tests') {
//             steps {
//                 sh 'mvn test -Dtest=*ApplicationTests'
//             }
//             post {
//                 always {
//                     junit '**/target/surefire-reports/*.xml'
//                 }
//             }
//         }

//         stage('Integration Tests') {
//             steps {
//                 catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
//                     sh 'mvn test -Pintegration-tests'
//                 }
//             }
//         }

//         stage('OWASP Dependency Check') {
//             steps {
//                 dependencyCheck additionalArguments: '--scan .', odcInstallation: 'default'
//                 dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
//             }
//         }

//     }
// }

// // pipeline {
// //     agent any
    
// //     tools {
// //         maven 'M3'  
// //         jdk 'OpenJDK 11' 
// //     }
    
// //     stages {
// //         stage('Checkout') {
// //             steps {
// //             }
// //         }
        
// //         stage('Build') {
// //             steps {
// //             }
// //         }
        
// //         stage('Dependency Scanning Parallel') {
// //             parallel {
              
// //             }
// //         }
// //         stage('Publish Dependency-Check Results') {
// //             steps {
               
// //             }
// //         }
// //         stage('Unit Tests') {
// //             steps {
// //             }
// //         }
        
// //         stage('Integration Tests') {
// //             steps {
// //             }
// //         }
        
// //         stage('Code Coverage') {
// //             steps {
             
// //             }
// //         }
        
// //         stage('SAST - SonarQube') {
// //             steps {
// //             }
// //         }
        
// //         stage('Package') {
// //             steps {
// //             }
// //         }
// //     }
    
// //     post {
// //         success {
// //             echo 'Pipeline completed successfully!'
// //         }
// //         failure {
// //             echo 'Pipeline failed!'
// //         }
// //     }
// // }



