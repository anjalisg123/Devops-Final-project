pipeline {
    agent any
    
    tools {
        maven 'M3'
        jdk 'OpenJDK 11'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Checkout stage completed successfully!'
            }
        }
        // ... more stages below
    }
}