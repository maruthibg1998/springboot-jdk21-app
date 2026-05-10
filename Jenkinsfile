pipeline {

    agent none

    environment {

        IMAGE_NAME = "pavankumarch1219/springboot-jdk21-app"
        TAG = "${BUILD_NUMBER}"

        JFROG_URL = "http://40.85.219.31:8082/artifactory/maven-local"

    }

    stages {

        stage('Build Maven Artifact') {

            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-21'
                    args '-v /root/.m2:/root/.m2'
                }
            }

            steps {

                git branch: 'main',
                url: 'https://github.com/pavankumarch1219/springboot-jdk21-app.git'

                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Run Tests') {

            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-21'
                    args '-v /root/.m2:/root/.m2'
                }
            }

            steps {

                sh 'mvn test'
            }

            post {

                always {

                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build & Push Docker Image') {

            agent any

            steps {

                script {

                    docker.build("${IMAGE_NAME}:${TAG}")

                    docker.withRegistry('', 'docker-creds') {

                        docker.image("${IMAGE_NAME}:${TAG}").push()

                        docker.image("${IMAGE_NAME}:${TAG}").push("latest")
                    }
                }
            }
        }

        stage('Upload to JFrog') {

            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-21'
                }
            }

            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'jfrog-creds',
                    usernameVariable: 'JFROG_USER',
                    passwordVariable: 'JFROG_PASS'
                )]) {

                    sh '''
                    curl -u $JFROG_USER:$JFROG_PASS \
                    -T target/*.jar \
                    "$JFROG_URL/artifactory/maven-local/"
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {

            agent {

                kubernetes {

                    defaultContainer 'kubectl'

                    yaml '''
apiVersion: v1
kind: Pod

spec:
  containers:

  - name: kubectl

    image: bitnami/kubectl:latest

    command:
    - sleep

    args:
    - "99d"

    tty: true
'''
                }
            }

            steps {

                container('kubectl') {

                    sh '''
                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml
                    kubectl get pods
                    '''
                }
            }
        }

        stage('Validate Deployment') {

            agent {

                kubernetes {

                    defaultContainer 'curl'

                    yaml '''
apiVersion: v1
kind: Pod

spec:
  containers:

  - name: curl

    image: curlimages/curl:latest

    command:
    - sleep

    args:
    - "99d"

    tty: true
'''
                }
            }

            steps {

                container('curl') {

                    sh '''
                    sleep 30

                    kubectl get pods

                    curl http://springboot-service
                    '''
                }
            }
        }

        stage('Approval Gate') {

            agent none

            steps {

                input message: 'Approve Destroy Stage?'
            }
        }

        stage('Destroy & Cleanup') {

            agent {

                kubernetes {

                    defaultContainer 'kubectl'

                    yaml '''
apiVersion: v1
kind: Pod

spec:
  containers:

  - name: kubectl

    image: bitnami/kubectl:latest

    command:
    - sleep

    args:
    - "99d"

    tty: true
'''
                }
            }

            steps {

                container('kubectl') {

                    sh '''
                    kubectl delete -f deployment.yaml
                    kubectl delete -f service.yaml
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
