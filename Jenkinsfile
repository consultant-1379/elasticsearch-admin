#!/usr/bin/env groovy

/* IMPORTANT:
 *
 * In order to make this pipeline work, the following configuration on Jenkins is required:
 * - slave with a specific label (see pipeline.agent.label below)
 * - credentials plugin should be installed and have the secrets with the following names:
 *   + lciadm100credentials (token to access Artifactory)
 */

def defaultBobImage = 'armdocker.rnd.ericsson.se/sandbox/adp-staging/adp-cicd/bob.2.0:1.5.2-0'
def bob = new BobCommand()
        .bobImage(defaultBobImage)
        .envVars([ISO_VERSION: '${ISO_VERSION}'])
        .needDockerSocket(true)
        .toString()
def GIT_COMMITTER_NAME = 'lciadm100'
def GIT_COMMITTER_EMAIL = 'lciadm100@ericsson.com'
def failedStage = ''
pipeline {
    agent {
        label 'Cloud-Native'
    }
    parameters {
        string(name: 'ISO_VERSION', description: 'The ENM ISO version (e.g. 1.65.77)')
        string(name: 'SPRINT_TAG', description: 'Tag for GIT tagging the repository after build')
    }
    stages {
        stage('Inject Credential Files') {
            steps {
                 withCredentials([file(credentialsId: 'lciadm100-docker-auth', variable: 'dockerConfig')]) {
                    sh "install -m 600 ${dockerConfig} ${HOME}/.docker/config.json"
                }
            }
        }
        stage('Checkout Cloud-Native SG Git Repository'){
            steps {
                git branch: 'master',
                        url: '${GERRIT_MIRROR}/OSS/ENM-Parent/SQ-Gate/com.ericsson.oss.presentation.server.logging/elasticsearch-admin'
                   sh '''
                      git remote set-url origin --push ${GERRIT_CENTRAL}/OSS/ENM-Parent/SQ-Gate/com.ericsson.oss.presentation.server.logging/elasticsearch-admin
                   '''
            }
        }
        stage('Helm Lint') {
            steps {
                sh "${bob} lint-helm"
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('ADP Helm Design Rule Check') {
            steps {
                sh "${bob} test-helm || true"
                archiveArtifacts 'design-rule-check-report.*'
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('Swap versions in Dockerfile and values.yaml file'){
            steps{
                echo sh(script: 'env', returnStdout:true)
                step ([$class: 'CopyArtifact', projectName: 'sync-build-trigger', filter: "*"]);
                sh "${bob} swap-latest-versions-with-numbers"
                sh '''
                    if git status | grep 'Dockerfile\\|values.yaml' > /dev/null; then
                        git commit -m "NO JIRA - Updating Dockerfile and Values.yaml files with base images version"
                        git push origin HEAD:master
                    else
                        echo `date` > timestamp
                        git add timestamp
                        git commit -m "NO JIRA - Time Stamp "
                        git push origin HEAD:master
                    fi
                '''
            }
        }
        stage('Build Image and Chart') {
            steps {
                sh "${bob} generate-new-version build-helm build-image-with-all-tags"
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                        sh "${bob} remove-image-with-all-tags"
                    }
                }
            }
        }
        stage('Retrieve image version') {
            steps {
                script {
                    env.IMAGE_TAG = sh(script: "cat .bob/var.version", returnStdout:true).trim()
                    echo "${IMAGE_TAG}"
                }
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                        sh "${bob} remove-image-with-all-tags"
                    }
                }
            }
        }
        stage('Generate ADP Parameters') {
            steps {
                sh "${bob} generate-output-parameters"
                archiveArtifacts 'artifact.properties'
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('Publish Images to Artifactory') {
             steps {
                sh "${bob} push-image-with-all-tags"
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                        sh "${bob} remove-image-with-all-tags"
                    }
                }
                always {
                    sh "${bob} remove-image-with-all-tags"
                }
            }
        }

       stage('Publish Helm Chart') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'lciadm100', variable: 'HELM_REPO_TOKEN')]) {
                        def bobWithHelmToken  = new BobCommand()
                                .bobImage(defaultBobImage)
                                .needDockerSocket(true)
                                .envVars(['HELM_REPO_TOKEN': env.HELM_REPO_TOKEN])
                                .toString()
                        sh "${bobWithHelmToken} push-helm"
                    }
                }
            }
        }
        stage('Tag Cloud-Native SG Git Repository') {
            steps {
                wrap([$class: 'BuildUser']) {
                    script {
                        def bobWithCommitterInfo = new BobCommand()
                                .bobImage(defaultBobImage)
                                .needDockerSocket(true)
                                .envVars([
                                        'AUTHOR_NAME'        : "\${BUILD_USER:-${GIT_COMMITTER_NAME}}",
                                        'AUTHOR_EMAIL'       : "\${BUILD_USER_EMAIL:-${GIT_COMMITTER_EMAIL}}",
                                        'GIT_COMMITTER_NAME' : "${GIT_COMMITTER_NAME}",
                                        'GIT_COMMITTER_EMAIL': "${GIT_COMMITTER_EMAIL}"
                                ])
                                .toString()
                        sh "${bobWithCommitterInfo} create-git-tag"
                        sh """
                            tag_id=\$(cat .bob/var.version)
                            git push origin \${tag_id}
                        """
                    }
                }
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
                always {
                    script {
                        sh "${bob} remove-git-tag"
                    }
                }
            }
        }
        stage('Generate Metadata Parameters') {
            steps {
                sh "${bob} generate-metadata-parameters"
                archiveArtifacts 'image-metadata-artifact.json'
            }
        }
    }
    post {
        success {
            script {
                sh '''
                    set +x
                    git tag --annotate --message "Tagging latest in sprint" --force $SPRINT_TAG HEAD
                    git push --force origin $SPRINT_TAG
                    git tag --annotate --message "Tagging latest in sprint with ISO version" --force ${SPRINT_TAG}_iso_${ISO_VERSION} HEAD
                    git push --force origin ${SPRINT_TAG}_iso_${ISO_VERSION}
                '''
            }
        }
        failure {
            mail to: 'teamstrikers@tcscomprod.onmicrosoft.com',
                    subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                    body: "Failure on ${env.BUILD_URL}"
        }
    }
}

// More about @Builder: http://mrhaki.blogspot.com/2014/05/groovy-goodness-use-builder-ast.html
import groovy.transform.builder.Builder
import groovy.transform.builder.SimpleStrategy
@Builder(builderStrategy = SimpleStrategy, prefix = '')
class BobCommand {
    def bobImage = 'bob.2.0:latest'
    def envVars = [:]
    def needDockerSocket = false

    String toString() {
        def env = envVars
                .collect({ entry -> "-e ${entry.key}=\"${entry.value}\"" })
                .join(' ')

        def cmd = """\
            |docker run
            |--init
            |--rm
            |--workdir \${PWD}
            |--user \$(id -u):\$(id -g)
            |-v \${PWD}:\${PWD}
            |-v /etc/group:/etc/group:ro
            |-v /etc/passwd:/etc/passwd:ro
            |-v \${HOME}/.m2:\${HOME}/.m2
            |-v \${HOME}/.docker:\${HOME}/.docker
            |${needDockerSocket ? '-v /var/run/docker.sock:/var/run/docker.sock' : ''}
            |${env}
            |\$(for group in \$(id -G); do printf ' --group-add %s' "\$group"; done)
            |${bobImage}
            |"""
        return cmd
                .stripMargin()           // remove indentation
                .replace('\n', ' ')      // join lines
                .replaceAll(/[ ]+/, ' ') // replace multiple spaces by one
    }
}
