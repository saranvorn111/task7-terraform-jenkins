pipeline {

    agent any

    environment {

        IMAGE = "foodexpress"

        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')

        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')

    }

    stages {

        stage('Checkout') {

            steps {

                git 'https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git'

            }

        }

        stage('Install') {

            steps {

                sh 'npm install'

            }

        }

        stage('Docker Build') {

            steps {

                sh 'docker build -t ${IMAGE} .'

            }

        }

        stage('Terraform Init') {

            steps {

                dir('terraform') {

                    sh 'terraform init'

                }

            }

        }

        stage('Terraform Apply') {

            steps {

                dir('terraform') {

                    sh 'terraform apply -auto-approve'

                }

            }

        }

        stage('Get Public IP') {

            steps {

                script {

                    env.PUBLIC_IP = sh(

                        script: "cd terraform && terraform output -raw public_ip",

                        returnStdout: true

                    ).trim()

                }

            }

        }

        stage('Deploy') {

            steps {

                sshagent(['EC2_SSH_KEY']) {

                    sh """

                    ssh -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} '

                    sudo apt update

                    sudo apt install docker.io -y

                    sudo systemctl enable docker

                    sudo systemctl start docker

                    '

                    """

                    sh """

                    scp -o StrictHostKeyChecking=no Dockerfile ubuntu@${PUBLIC_IP}:~

                    """

                    sh """

                    scp -r . ubuntu@${PUBLIC_IP}:~/app

                    """

                    sh """

                    ssh -o StrictHostKeyChecking=no ubuntu@${PUBLIC_IP} '

                    cd ~/app

                    sudo docker build -t foodexpress .

                    sudo docker rm -f foodexpress || true

                    sudo docker run -d -p 3000:3000 --name foodexpress foodexpress

                    '

                    """

                }

            }

        }

    }

}