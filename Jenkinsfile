pipeline {

    agent none

    environment {

        IMAGE_NAME = "pavankumarch1219/springboot-jdk21-app"
        TAG = "${BUILD_NUMBER}"

        JFROG_URL = "http://40.85.219.31:8082/artifactory/maven-local"

        APP_NAME = "springboot-app"
    }

    stages {

        stage('Build Maven Artifact') {

            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-21'
                    args '-v /root/.m2:/root/.m2'
                    reuseNode true
                }
            }

            steps {

                git branch: 'main',
                url: 'https://github.com/pavankumarch1219/springboot-jdk21-app.git'

                sh '''
                mvn clean package -DskipTests

                cp target/*.jar springboot.jar

                ls -lrt
                '''
            }
        }

        stage('Run Tests') {

            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-21'
                    args '-v /root/.m2:/root/.m2'
                    reuseNode true
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

            agent {
                docker {
                    image 'docker:27-cli'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                    reuseNode true
                }
            }

            steps {

                script {

                    sh '''
                    docker version
                    '''

                    sh '''
                    docker build -t ${IMAGE_NAME}:${TAG} .
                    '''

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
                    reuseNode true
                }
            }

            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'jfrog-creds',
                    usernameVariable: 'JFROG_USER',
                    passwordVariable: 'JFROG_PASS'
                )]) {

                    sh '''
                    echo "Uploading JAR to JFrog..."

                    curl -v -u $JFROG_USER:$JFROG_PASS \
                    -T springboot.jar \
                    "$JFROG_URL/springboot-${BUILD_NUMBER}.jar"
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
  serviceAccountName: default

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
                    kubectl version --client

                    kubectl apply -f deployment.yaml

                    kubectl apply -f service.yaml

                    kubectl get deployments

                    kubectl get svc

                    kubectl get pods
                    '''
                }
            }
        }

        stage('Validate Deployment') {

            agent {

                kubernetes {

                    defaultContainer 'kubectl'

                    yaml '''
apiVersion: v1
kind: Pod

spec:
  serviceAccountName: default

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
                    echo "Waiting for application startup..."

                    sleep 40

                    kubectl get pods

                    kubectl get svc

                    kubectl rollout status deployment/${APP_NAME}

                    kubectl port-forward svc/springboot-service 8080:8080 > /dev/null 2>&1 &

                    sleep 10

                    curl http://localhost:8080
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
  serviceAccountName: default

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
                    kubectl delete -f deployment.yaml --ignore-not-found=true

                    kubectl delete -f service.yaml --ignore-not-found=true

                    kubectl get pods

                    kubectl get svc
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
