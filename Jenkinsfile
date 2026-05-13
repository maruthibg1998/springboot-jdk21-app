pipeline {

    agent {
        kubernetes {
            inheritFrom 'jnlp'
        }
    }

    environment {
        IMAGE_NAME = "maruthibg1998/springboot-jdk21-app"
        TAG = "${BUILD_NUMBER}"
        JFROG_URL = "http://20.249.148.1:8081/artifactory/maven-repo"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                credentialsId: 'github_creds',
                url: 'https://github.com/maruthibg1998/springboot-jdk21-app.git'
            }
        }

        stage('Build Maven Artifact') {
            steps {
                container('maven') {
                    sh '''
                    mvn clean package -DskipTests
                    cp target/*.jar springboot.jar
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                container('maven') {
                    sh 'mvn test'
                }
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Upload JAR to JFrog') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'jfrog_creds',
                    usernameVariable: 'JFROG_USER',
                    passwordVariable: 'JFROG_PASS'
                )]) {
                    sh '''
                    curl -u $JFROG_USER:$JFROG_PASS \
                    -T springboot.jar \
                    "$JFROG_URL/springboot-${BUILD_NUMBER}.jar"
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml
                    '''
                }
            }
        }

        stage('Validate Deployment') {
            steps {
                container('kubectl') {
                    sh '''
                    kubectl rollout status deployment/springboot-app --timeout=180s
                    kubectl get pods
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline Executed Successfully'
        }
        failure {
            echo 'Pipeline Failed'
        }
    }
}
