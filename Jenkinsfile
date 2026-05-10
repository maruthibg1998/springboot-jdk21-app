pipeline {

    agent any

    environment {

        IMAGE_NAME = "pavankumarch1219/springboot-jdk21-app"
        TAG = "${BUILD_NUMBER}"

        JFROG_URL = "http://40.85.219.31:8082/artifactory/maven-local"
    }

    stages {

        stage('Checkout Code') {

            steps {

                git branch: 'main',
                credentialsId: 'github-creds',
                url: 'https://github.com/pavankumarch1219/springboot-jdk21-app.git'
            }
        }

        stage('Build Maven Artifact') {

            steps {

                sh '''
                mvn clean package -DskipTests

                cp target/*.jar springboot.jar

                ls -lrt
                '''
            }
        }

        stage('Run Tests') {

            steps {

                sh '''
                mvn test
                '''
            }

            post {

                always {

                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build Docker Image') {

            steps {

                sh '''
                docker build -t ${IMAGE_NAME}:${TAG} .

                docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Push Docker Image') {

            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'docker-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                    docker push ${IMAGE_NAME}:${TAG}

                    docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Upload JAR to JFrog') {

            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'jfrog-creds',
                    usernameVariable: 'JFROG_USER',
                    passwordVariable: 'JFROG_PASS'
                )]) {

                    sh '''
                    curl -v -u $JFROG_USER:$JFROG_PASS \
                    -T springboot.jar \
                    "$JFROG_URL/springboot-${BUILD_NUMBER}.jar"
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {

            steps {

                sh '''
                kubectl apply -f deployment.yaml

                kubectl apply -f service.yaml

                kubectl get deployments

                kubectl get pods

                kubectl get svc
                '''
            }
        }

        stage('Validate Deployment') {

            steps {

                sh '''
                kubectl rollout status deployment/springboot-app --timeout=180s

                kubectl get pods

                kubectl get svc
                '''
            }
        }

        stage('Approval Gate') {

            steps {

                input message: 'Approve Cleanup Stage?'
            }
        }

        stage('Destroy Deployment') {

            steps {

                sh '''
                kubectl delete -f deployment.yaml --ignore-not-found=true

                kubectl delete -f service.yaml --ignore-not-found=true
                '''
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
