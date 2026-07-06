pipeline {
    agent any

    environment {
        APP_NAME   = "register"
        IMAGE_TAG  = "latest"
        TF_DIR     = "terraform"
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
                    aws --version
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t register:latest .
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            terraform init
                        '''
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform validate
                    '''
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
                        sh '''
                            terraform plan -out=tfplan
                        '''
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
                        sh '''
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                script {
                    env.EC2_IP = sh(
                        script: "cd terraform && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    echo "EC2 Public IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Wait for EC2') {
            steps {
                echo "Waiting for EC2..."
                sleep(time: 60, unit: 'SECONDS')
            }
        }

        stage('Deploy Application') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no \
                            -i "$SSH_KEY" \
                            "$SSH_USER@$EC2_IP" \
                            "mkdir -p ~/app"

                        scp -o StrictHostKeyChecking=no \
                            -i "$SSH_KEY" \
                            -r ./* \
                            "$SSH_USER@$EC2_IP:~/app/"

                        ssh -o StrictHostKeyChecking=no \
                            -i "$SSH_KEY" \
                            "$SSH_USER@$EC2_IP" << 'EOF'

                            if command -v apt >/dev/null 2>&1; then
                                sudo apt update
                                sudo apt install -y docker.io
                            elif command -v dnf >/dev/null 2>&1; then
                                sudo dnf install -y docker
                            fi

                            sudo systemctl enable docker
                            sudo systemctl start docker

                            cd ~/app

                            sudo docker build -t register .

                            sudo docker rm -f register || true

                            sudo docker run -d \
                                --name register \
                                -p 3000:3000 \
                                register
EOF
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 30
                    curl --fail http://$EC2_IP:3000
                '''
            }
        }
    }

    post {
        success {
            echo "Application deployed successfully."
            echo "http://${EC2_IP}:3000"
        }

        failure {
            echo "Pipeline failed."
        }

        always {
            cleanWs()
        }
    }
}