import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.dockerSupport
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.retryBuild
import jetbrains.buildServer.configs.kotlin.triggers.schedule
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the

    mvnDebug org.jetbrains.teamcity:teamcity-configs-maven-plugin:generate

command and attach your debugger to the port 8000.

To debug in IntelliJ Idea, open the 'Maven Projects' tool window (View
-> Tool Windows -> Maven Projects), find the generate task node
(Plugins -> teamcity-configs -> teamcity-configs:generate), the
'Debug' option is available in the context menu for the task.
*/

version = "2022.10"

project {

    buildType(PhpComposerNginx)
}

object PhpComposerNginx : BuildType({
    name = "php-composer-nginx"

    artifactRules = "trivy/report.html => trivy.zip"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        dockerCommand {
            name = "Build"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
                namesAndTags = "statscore/php-composer-nginx:8.1"
            }
        }
        script {
            name = "Vulnerability scan"
            scriptContent = """trivy image --format template --template "@/contrib/html.tpl" -o /trivy/report.html sportsapi:beta"""
            dockerImage = "aquasec/trivy"
            dockerRunParameters = "-v /var/run/docker.sock:/var/run/docker.sock -v %system.teamcity.build.checkoutDir%/trivy:/trivy"
        }
        dockerCommand {
            name = "Push"
            commandType = push {
                namesAndTags = "statscore/php-composer-nginx:8.1"
            }
        }
    }

    triggers {
        vcs {
        }
        schedule {
            schedulingPolicy = daily {
                hour = 6
            }
            triggerBuild = always()
        }
        retryBuild {
            delaySeconds = 180
            attempts = 1
        }
    }

    features {
        perfmon {
        }
        dockerSupport {
            loginToRegistry = on {
                dockerRegistryId = "PROJECT_EXT_3"
            }
        }
    }
})