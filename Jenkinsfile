#!groovy

pipeline {
    agent { node { label 'linux' } }
    tools {
        maven 'maven3'
    }
//  triggers {
//    upstream(upstreamProjects: 'tck/tck-olamy-github-tck-run-module-glassfish') //, threshold: hudson.model.Result.SUCCESS)
//  }
    options {
        buildDiscarder logRotator( numToKeepStr: '50' )
    }
    parameters {

        string( defaultValue: 'jetty-12.0.10', description: 'GIT branch name to build Jetty (jetty-12.0.10)',
                name: 'JETTY_TAG' )

        string( defaultValue: 'jdk17', description: 'JDK to build Jetty', name: 'JDKBUILD' )

        string( defaultValue: '', description: 'Extra Maven Args', name: 'MVN_ARGS' )

        choice( description: 'Javadoc branch',
                name: 'JAVADOC_PATH',
                choices: ['jetty-12','jetty-11','jetty-10','jetty-9'] )

    }

    stages {

        stage("Checkout Jetty Sources/ Build Javadoc") {
            steps {
                ws('tmp') {
                    sh "ls -lrt"
                    checkout([$class           : 'GitSCM',
                              branches         : [[name: "$JETTY_TAG"]],
                              extensions       : [[$class: 'CloneOption', depth: 1, shallow: true, reference: "/home/jenkins/jetty.project.git"]],
                              userRemoteConfigs: [[url: 'https://github.com/eclipse/jetty.project.git']]])
                    timeout(time: 30, unit: 'MINUTES') {
                        withEnv(["JAVA_HOME=${tool "$JDKBUILD"}",
                                 "PATH+MAVEN=${env.JAVA_HOME}/bin:${tool 'maven3'}/bin",
                                 "MAVEN_OPTS=-Xms10g -Xmx10g -Djava.awt.headless=true"]) {
                            configFileProvider([configFile(fileId: 'oss-settings.xml', variable: 'GLOBAL_MVN_SETTINGS')]) {
                                sh "mvn -ntp -s $GLOBAL_MVN_SETTINGS -V -B clean install -e -DskipTests -T3 -Dmaven.build.cache.enabled=false"
                                sh "ls -lrt"
                                stash includes: 'javadoc/target/apidocs/**/*', name: 'apidocs'
                            }
                        }
                    }
                }
            }
        }
        stage("Commit new Javadoc") {
            environment {
                GIT_AUTH = credentials('github-app-jetty-project')
            }
            steps {

                sh('''
                    //git clone https://github.com/jetty-project/javadoc.jetty.org.git                                    
                    git config user.name '$GIT_AUTH_USR'
                    git config user.email '$GIT_AUTH_USR@users.noreply.webtide.com'       
                    git checkout main         
                ''')


//                checkout([$class           : 'GitSCM',
//                          branches         : [[name: "*/main"]],
//                          userRemoteConfigs: [[url: 'https://github.com/jetty-project/javadoc.jetty.org.git']]])

                unstash 'apidocs'
                sh 'ls -lrt'
                sh 'ls -lrt javadoc'
                sh 'cp -r javadoc/target/apidocs/* $JAVADOC_PATH/'
                sh 'rm -rf javadoc'
                sh "git status"
            }
        }
    }
}