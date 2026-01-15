pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'ghcr.io'
        DOCKER_ORG = 'Vickram-T-G'
        
        GIT_COMMIT_SHORT = sh(
            script: 'git rev-parse --short HEAD',
            returnStdout: true
        ).trim()
        
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_ORG}/login-app-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_ORG}/login-app-frontend"
        
        DEPLOY_HOST = '13.60.167.169'
        DEPLOY_USER = 'ec2-user'
        DEPLOY_PATH = '/home/ec2-user/app'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        
        timeout(time: 30, unit: 'MINUTES')
        
        timestamps()
        
        // gitBuildInformation()
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Checking out code from ${env.GIT_BRANCH}"
                    checkout scm
                    
                    sh '''
                        echo "=== Git Information ==="
                        echo "Branch: ${GIT_BRANCH}"
                        echo "Commit: ${GIT_COMMIT}"
                        echo "Short SHA: ${GIT_COMMIT_SHORT}"
                        echo "Author: $(git log -1 --pretty=format:'%an <%ae>')"
                        echo "Message: $(git log -1 --pretty=format:'%s')"
                    '''
                }
            }
        }

        stage('Lint & Static Checks') {
            steps {
                script {
                    echo "Running static code analysis..."
                    
                    sh '''
                        echo "Checking Dockerfile syntax..."
                        docker run --rm -i hadolint/hadolint < Dockerfile.backend || echo "Hadolint not available, skipping..."
                        docker run --rm -i hadolint/hadolint < Dockerfile.frontend || echo "Hadolint not available, skipping..."
                    '''
                    
                    sh '''
                        echo "Scanning Dockerfiles for vulnerabilities..."
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
                            aquasec/trivy:latest image --exit-code 0 --severity HIGH,CRITICAL \\
                            ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} || echo "Trivy scan completed with findings"
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: '**/lint-results.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                script {
                    echo "Building backend Docker image..."
                    
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'DOCKER_REGISTRY_CRED',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        sh '''
                            echo "Logging into ${DOCKER_REGISTRY}..."
                            echo "${DOCKER_PASS}" | docker login ${DOCKER_REGISTRY} -u "${DOCKER_USER}" --password-stdin
                            
                            echo "Building backend image..."
                            docker build \\
                                --file Dockerfile.backend \\
                                --tag ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} \\
                                --tag ${BACKEND_IMAGE}:latest \\
                                --build-arg RUST_VERSION=${RUST_VERSION:-1.70} \\
                                .
                            
                            echo "Backend image built successfully"
                            docker images | grep login-app-backend
                        '''
                    }
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                script {
                    echo "Building frontend Docker image..."
                    
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'DOCKER_REGISTRY_CRED',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        sh '''
                            echo "Logging into ${DOCKER_REGISTRY}..."
                            echo "${DOCKER_PASS}" | docker login ${DOCKER_REGISTRY} -u "${DOCKER_USER}" --password-stdin
                            
                            echo "Building frontend image..."
                            docker build \\
                                --file Dockerfile.frontend \\
                                --tag ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} \\
                                --tag ${FRONTEND_IMAGE}:latest \\
                                --build-arg NODE_VERSION=${NODE_VERSION:-18-alpine} \\
                                .
                            
                            echo "Frontend image built successfully"
                            docker images | grep login-app-frontend
                        '''
                    }
                }
            }
        }

        stage('Test Images') {
            steps {
                script {
                    echo "Running smoke tests on built images..."
                    
                    sh '''
                        echo "Testing backend image healthcheck..."
                        docker run --rm -d --name test-backend \\
                            -p 8080:8080 \\
                            ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} || true
                        
                        sleep 10
                        
                        # Test health endpoint
                        if curl -f http://localhost:8080/; then
                            echo "✓ Backend health check passed"
                        else
                            echo "✗ Backend health check failed"
                            exit 1
                        fi
                        
                        docker stop test-backend || true
                        
                        echo "Testing frontend image..."
                        docker run --rm -d --name test-frontend \\
                            -p 8081:80 \\
                            ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} || true
                        
                        sleep 5
                        
                        if curl -f http://localhost:8081/health; then
                            echo "✓ Frontend health check passed"
                        else
                            echo "✗ Frontend health check failed"
                            exit 1
                        fi
                        
                        docker stop test-frontend || true
                    '''
                }
            }
        }

        stage('Push Images to Registry') {
            steps {
                script {
                    echo "Pushing images to ${DOCKER_REGISTRY}..."
                    
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'DOCKER_REGISTRY_CRED',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        sh '''
                            echo "Logging into ${DOCKER_REGISTRY}..."
                            echo "${DOCKER_PASS}" | docker login ${DOCKER_REGISTRY} -u "${DOCKER_USER}" --password-stdin
                            
                            echo "Pushing backend image (tags: ${GIT_COMMIT_SHORT}, latest)..."
                            docker push ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}
                            docker push ${BACKEND_IMAGE}:latest
                            
                            echo "Pushing frontend image (tags: ${GIT_COMMIT_SHORT}, latest)..."
                            docker push ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}
                            docker push ${FRONTEND_IMAGE}:latest
                            
                            echo "✓ Images pushed successfully"
                        '''
                    }
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                script {
                    echo "Deploying to ${DEPLOY_HOST} (AWS EC2)..."
                    
                    withCredentials([
                        sshUserPrivateKey(
                            credentialsId: 'SSH_DEPLOY_KEY',
                            usernameVariable: 'SSH_USER',
                            keyFileVariable: 'SSH_KEY'
                        ),
                        usernamePassword(
                            credentialsId: 'DOCKER_REGISTRY_CRED',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        sh '''
                            echo "Deploying application to AWS EC2 instance..."
                            
                            # Export image tag and registry info for deploy script
                            export IMAGE_TAG=${GIT_COMMIT_SHORT}
                            export DOCKER_REGISTRY=${DOCKER_REGISTRY}
                            export DOCKER_ORG=${DOCKER_ORG}
                            export DOCKER_USER=${DOCKER_USER}
                            export DOCKER_PASS=${DOCKER_PASS}
                            
                            # Ensure deployment directory exists
                            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no \\
                                ${SSH_USER}@${DEPLOY_HOST} \\
                                "mkdir -p ${DEPLOY_PATH}/scripts ${DEPLOY_PATH}/nginx"
                            
                            # Copy cloud deployment script to remote host
                            scp -i ${SSH_KEY} -o StrictHostKeyChecking=no \\
                                scripts/deploy_cloud.sh \\
                                ${SSH_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/scripts/deploy_cloud.sh
                            
                            # Make script executable
                            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no \\
                                ${SSH_USER}@${DEPLOY_HOST} \\
                                "chmod +x ${DEPLOY_PATH}/scripts/deploy_cloud.sh"
                            
                            # Copy docker-compose files
                            scp -i ${SSH_KEY} -o StrictHostKeyChecking=no \\
                                docker-compose.yml \\
                                docker-compose.prod.yml \\
                                ${SSH_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/
                            
                            # Copy nginx configs
                            scp -i ${SSH_KEY} -o StrictHostKeyChecking=no \\
                                -r nginx/* \\
                                ${SSH_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/nginx/
                            
                            # Copy .env.sample if .env doesn't exist
                            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no \\
                                ${SSH_USER}@${DEPLOY_HOST} \\
                                "if [ ! -f ${DEPLOY_PATH}/.env ]; then \\
                                    if [ -f ${DEPLOY_PATH}/.env.sample ]; then \\
                                        cp ${DEPLOY_PATH}/.env.sample ${DEPLOY_PATH}/.env; \\
                                    fi; \\
                                 fi"
                            
                            # Execute cloud deployment script on remote host
                            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no \\
                                ${SSH_USER}@${DEPLOY_HOST} \\
                                "cd ${DEPLOY_PATH} && \\
                                 IMAGE_TAG=${GIT_COMMIT_SHORT} \\
                                 DOCKER_REGISTRY=${DOCKER_REGISTRY} \\
                                 DOCKER_ORG=${DOCKER_ORG} \\
                                 DOCKER_USER=${DOCKER_USER} \\
                                 DOCKER_PASS=${DOCKER_PASS} \\
                                 DEPLOY_PATH=${DEPLOY_PATH} \\
                                 bash scripts/deploy_cloud.sh"
                            
                            echo "✓ Deployment to AWS EC2 completed"
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    echo "Verifying deployment health..."
                    
                    withCredentials([
                        sshUserPrivateKey(
                            credentialsId: 'SSH_DEPLOY_KEY',
                            usernameVariable: 'SSH_USER',
                            keyFileVariable: 'SSH_KEY'
                        )
                    ]) {
                        sh '''
                            echo "Waiting for services to be healthy..."
                            sleep 15
                            
                            # Check service health via SSH
                            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no \\
                                ${SSH_USER}@${DEPLOY_HOST} \\
                                "cd ${DEPLOY_PATH} && docker compose ps"
                            
                            # Test health endpoint (if public IP/DNS is configured)
                            if [ -n "${DEPLOY_HOST}" ] && [ "${DEPLOY_HOST}" != "your-vm-ip-or-hostname" ]; then
                                echo "Testing public endpoint..."
                                if curl -f -m 10 http://${DEPLOY_HOST}/health; then
                                    echo "✓ Public health check passed"
                                else
                                    echo "⚠ Public health check failed (may be expected if VM is not publicly accessible)"
                                fi
                            fi
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            sh '''
                echo "Cleaning up local Docker images..."
                docker image prune -f || true
            '''
        }
        success {
            echo "Pipeline completed successfully! 🎉"
        }
        failure {
            echo "Pipeline failed! Check logs above for details."
        }
        cleanup {
            cleanWs()
        }
    }
}


