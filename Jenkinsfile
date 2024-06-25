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
        buildDiscarder logRotator( numToKeepStr: '30' )
    }
    parameters {

        string( defaultValue: 'jetty-12.0.10', description: 'GIT branch name to build Jetty (jetty-12.0.10)',
                name: 'JETTY_TAG' )

        string( defaultValue: 'jdk17', description: 'JDK to build Jetty', name: 'JDKBUILD' )

        string( defaultValue: 'clean install -T3 -Dmaven.build.cache.enabled=false', description: 'Maven Args for jetty 9 use verify org.apache.maven.plugins:maven-javadoc-plugin:3.7.0:aggregate -DlegacyMode=true -T5', name: 'MVN_GOALS' )

        string( defaultValue: '-ntp -V -B -e -DskipTests ', description: 'Extra Maven Args', name: 'MVN_ARGS' )

        string( defaultValue: 'javadoc/target/apidocs', description: 'Javadoc path (for Jetty 9 use target/site/apidocs)', name: 'JAVADOC_LOCAL_PATH' )

        choice( description: 'Javadoc branch',
                name: 'JAVADOC_PATH',
                choices: ['jetty-12','jetty-11','jetty-10','jetty-9'] )

    }

    stages {

        stage("Checkout Jetty Sources/ Build Javadoc") {
            steps {
                ws('tmp') {
                    checkout([$class           : 'GitSCM',
                              branches         : [[name: "$JETTY_TAG"]],
                              extensions       : [[$class: 'CloneOption', depth: 1, shallow: true, reference: "/home/jenkins/jetty.project.git"]],
                              userRemoteConfigs: [[url: 'https://github.com/eclipse/jetty.project.git']]])
                    timeout(time: 30, unit: 'MINUTES') {
                        withEnv(["JAVA_HOME=${tool "$JDKBUILD"}",
                                 "PATH+MAVEN=${env.JAVA_HOME}/bin:${tool 'maven3'}/bin",
                                 "MAVEN_OPTS=-Xms10g -Xmx10g -Djava.awt.headless=true"]) {
                            configFileProvider([configFile(fileId: 'oss-settings.xml', variable: 'GLOBAL_MVN_SETTINGS')]) {
                                sh "mvn -s $GLOBAL_MVN_SETTINGS $MVN_ARGS $MVN_GOALS"
                                stash includes: "$JAVADOC_LOCAL_PATH/**/*", name: "apidocs"
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
                    git config user.name '$GIT_AUTH_USR'
                    git config user.email '$GIT_AUTH_USR@users.noreply.webtide.com'       
                    git checkout main         
                ''')

                unstash 'apidocs'

                script {
                    if("$JAVADOC_PATH" != 'jetty-12') {
                        sh('''
                            echo "need to update canonical because $JAVADOC_PATH"
                            bash ./_update_canonical_links.sh $JAVADOC_PATH
                        ''')
                    } else {
                        sh "in jetty 12 no need to _update_canonical_links"
                    }
                }
                sh('''
                    ls -lrt
                    ls -lrt $JAVADOC_LOCAL_PATH
                    cp -r $JAVADOC_LOCAL_PATH/* $JAVADOC_PATH/
                    rm -rf javadoc
                    git status
                    #git add -A $JAVADOC_PATH/
                    #git commit -a"update javadoc for $JETTY_TAG in path $JAVADOC_PATH"

                
                    git config --local credential.helper "!f() { echo username=\\$GIT_AUTH_USR; echo password=\\$GIT_AUTH_PSW; }; f"
                    #git push origin main
                ''')
            }
        }
    }
}