pipeline {
    agent any

    environment {
        APP_NAME = "register"
        IMAGE_TAG = "latest"
        TF_DIR = "terraform"
        AWS_REGION = "us-east-1"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    docker --version
                    terraform --version
                    aws --version || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${APP_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh "terraform init"
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh "terraform validate"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh "terraform plan -out=tfplan"
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh "terraform apply -auto-approve tfplan"
                    }
                }
            }
        }

        stage('Get Public IP') {
            steps {
                script {
                    env.EC2_IP = sh(
                        script: "cd ${TF_DIR} && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    echo "EC2 IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    echo "Waiting for app..."
                    sleep 60
                    curl --fail http://${EC2_IP}:3000
                """
            }
        }
    }

    post {
        success {
            echo "PIPELINE SUCCESS - http://${EC2_IP}:3000"
        }

        failure {
            echo "PIPELINE FAILED"
        }

        always {
            cleanWs()
        }
    }
}