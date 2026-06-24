// Load the Jenkins Shared Library named "Shared" (configure under Manage Jenkins → Configure System).
// Functions like clean_ws(), clone(), docker_build(), etc. are defined in that library repo.
@Library('Shared') _

pipeline {
    // Run on any available Jenkins agent (the Jenkins EC2 server has Docker installed).
    agent any

    environment {
        // Docker Hub image names — must match kubernetes/*.yaml and your Docker Hub account (simsoliver).
        DOCKER_IMAGE_NAME = 'simsoliver/easyshop-app'
        DOCKER_MIGRATION_IMAGE_NAME = 'simsoliver/easyshop-migration'

        // Tag each build with the Jenkins build number (e.g. simsoliver/easyshop-app:42).
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"

        // Loads Jenkins credential ID "github-credentials" (Manage Jenkins → Credentials).
        // Username = GitHub username (oliversims), Password = GitHub Personal Access Token.
        // Exposes GITHUB_CREDENTIALS_USR and GITHUB_CREDENTIALS_PSW to the pipeline.
        GITHUB_CREDENTIALS = credentials('github-credentials')

        // Branch to clone and deploy from.
        GIT_BRANCH = "master"

        // Your GitHub repo — manifest updates are pushed here (not lax66).
        GIT_REPO_URL = "https://github.com/oliversims/tws-e-commerce-app_hackathon.git"
    }

    stages {
        // Remove leftover files from previous builds on the Jenkins workspace.
        stage('Cleanup Workspace') {
            steps {
                script {
                    clean_ws()
                }
            }
        }

        // Clone from YOUR repo (do not use shared library clone() — it hardcodes lax66).
        stage('Clone Repository') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-credentials',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )]) {
                        sh '''
                            git clone -b master \
                              "https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/oliversims/tws-e-commerce-app_hackathon.git" \
                              .
                        '''
                    }
                }
            }
        }

        // Build both Docker images at the same time to save time.
        stage('Build Docker Images') {
            parallel {
                // Main Next.js application image.
                stage('Build Main App Image') {
                    steps {
                        script {
                            docker_build(
                                imageName: env.DOCKER_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                dockerfile: 'Dockerfile',
                                context: '.'
                            )
                        }
                    }
                }

                // Database migration image (runs schema migrations before/at deploy).
                stage('Build Migration Image') {
                    steps {
                        script {
                            docker_build(
                                imageName: env.DOCKER_MIGRATION_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                dockerfile: 'scripts/Dockerfile.migration',
                                context: '.'
                            )
                        }
                    }
                }
            }
        }

        // Run application unit tests inside the built image or workspace.
        stage('Run Unit Tests') {
            steps {
                script {
                    run_tests()
                }
            }
        }

        // Scan images for known CVEs using Trivy (installed on the Jenkins server).
        stage('Security Scan with Trivy') {
            steps {
                script {
                    trivy_scan()
                }
            }
        }

        // Push both images to Docker Hub (requires credential ID "docker-hub-credentials").
        stage('Push Docker Images') {
            parallel {
                stage('Push Main App Image') {
                    steps {
                        script {
                            docker_push(
                                imageName: env.DOCKER_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                credentials: 'docker-hub-credentials'
                            )
                        }
                    }
                }

                stage('Push Migration Image') {
                    steps {
                        script {
                            docker_push(
                                imageName: env.DOCKER_MIGRATION_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                credentials: 'docker-hub-credentials'
                            )
                        }
                    }
                }
            }
        }

        // Update kubernetes/*.yaml with the new image tag and commit/push to YOUR repo.
        // (The Shared library's update_k8s_manifests still points at lax66 — we do this inline instead.)
        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-credentials',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )]) {
                        sh """
                            git config user.name "Jenkins CI"
                            git config user.email "misc.lucky66@gmail.com"

                            sed -i "s|image: .*easyshop-app.*|image: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}|g" kubernetes/08-easyshop-deployment.yaml

                            if [ -f kubernetes/12-migration-job.yaml ]; then
                                sed -i "s|image: .*easyshop-migration.*|image: ${env.DOCKER_MIGRATION_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}|g" kubernetes/12-migration-job.yaml
                            fi

                            if git diff --quiet; then
                                echo "No manifest changes to commit"
                            else
                                git add kubernetes/*.yaml
                                git commit -m "Update image tags to ${env.DOCKER_IMAGE_TAG} [ci skip]"
                                git remote -v
                                git push "https://\${GIT_USERNAME}:\${GIT_PASSWORD}@github.com/oliversims/tws-e-commerce-app_hackathon.git" HEAD:${env.GIT_BRANCH}
                            fi
                        """
                    }
                }
            }
        }
    }
}
