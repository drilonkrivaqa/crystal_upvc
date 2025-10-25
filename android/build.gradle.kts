import java.io.File

fun File.removeEscapedSpaces(): File =
    File(path.replace("\\ ", " "))

val sanitizedRootBuildDir = File(rootProject.projectDir.absolutePath.replace("\\ ", " "), "build").removeEscapedSpaces()

rootProject.buildDir = sanitizedRootBuildDir
rootProject.layout.buildDirectory.set(sanitizedRootBuildDir)

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
