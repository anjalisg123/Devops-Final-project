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
        stage('Dependency Scanning') {
            parallel {
                stage('OWASP Dependency-Check') {
                    steps {
                        sh '''
                            mvn -B org.owasp:dependency-check-maven:check \
                            -DfailBuildOnCVSS=9 \
                            -DnvdApiKey=486ad32f-d3aa-4605-98e5-1753655999cb \
                            -DdataDirectory="$WORKSPACE/.dc-data" \
                            -Dformats=HTML,XML
                        '''
                        stash name: 'owasp-reports', includes: 'target/dependency-check-report.*'
                        echo 'OWASP Dependency-Check completed!'
                    }
                }
                stage('Maven Dependency Audit') {
                    steps {
                        sh 'mvn versions:display-dependency-updates'
                        echo 'Maven Dependency Audit completed!'
                    }
                }
            }
        }

        stage('Publish Dependency-Check Results') {
            steps {
                unstash 'owasp-reports'
                dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                publishHTML(target: [
                    reportName: 'Dependency Check HTML Report',
                    reportDir: 'target',
                    reportFiles: 'dependency-check-report.html',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: false
                ])
                echo 'Dependency-Check results published!'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'mvn test'
                echo 'Unit tests completed!'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Integration Tests') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh 'mvn test -Pintegration-tests'
                }
                echo 'Integration tests stage completed!'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Code Coverage') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh 'mvn jacoco:report'
                }
                publishHTML(target: [
                    reportName: 'Code Coverage HTML Report',
                    reportDir: 'target/site/jacoco',
                    reportFiles: 'index.html',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: false
                ])
                echo 'Code coverage report published!'
            }
        }

        stage('SAST - SonarQube') {
            steps {
                sh '''
                    mvn clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                    -Dsonar.projectKey=Book-System-Project \
                    -Dsonar.projectName=Book-System-Project \
                    -Dsonar.java.binaries=target/classes \
                    -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                    -Dsonar.host.url=http://localhost:9000 \
                    -Dsonar.token=sqp_6f12f5d4346317cf05843784e549054f366bd1fb
                '''
                echo 'SonarQube analysis completed!'
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



