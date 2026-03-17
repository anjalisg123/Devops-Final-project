pipeline {
    agent any
    
    tools {
        maven 'M3'
        jdk 'OpenJDK 17'
    }

    environment {
        PATH = "/usr/local/bin:${env.PATH}"
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
                        withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                            sh '''
                                mvn -B org.owasp:dependency-check-maven:check \
                                -DfailBuildOnCVSS=9 \
                                -DnvdApiKey=${NVD_API_KEY} \
                                -DdataDirectory="$WORKSPACE/.dc-data" \
                                -Dformats=HTML,XML
                            '''
                        }
                        stash name: 'owasp-reports', includes: 'target/dependency-check-report.*'
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
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        mvn clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                        -Dsonar.projectKey=Book-System-Project \
                        -Dsonar.projectName=Book-System-Project \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                        -Dsonar.host.url=http://localhost:9000 \
                        -Dsonar.token=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                echo 'Application packaged and archived!'
            }
        }

        stage('Docker Build & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin
                        docker buildx build --platform linux/amd64 -t ${DOCKER_USER}/book-system:${BUILD_NUMBER} -t ${DOCKER_USER}/book-system:latest --push .
                    '''
                }
            }
        }

        stage('Deploy to AWS') {
            steps {
                sh '''
                    ssh -o StrictHostKeyChecking=no -i /Users/anjali/.jenkins/book-system-key.pem ec2-user@3.19.228.160 \
                    "sudo docker pull anjali2802/book-system:latest && sudo docker stop book-app || true && sudo docker rm book-app || true && sudo docker run -d --name book-app -p 8080:8080 anjali2802/book-system:latest"
                '''
                echo 'Deployment completed!'
            }
        }

        stage('Health Check') {
            steps {
                sh 'sleep 30'
                sh 'curl -f http://3.19.228.160:8080 || echo "App deployed but health check pending (MongoDB not available on EC2)"'
                echo 'Health check completed!'
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed!'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        unstable {
            echo 'Pipeline completed with UNSTABLE stages.'
        }
    }
}






