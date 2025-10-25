import java.io.File
import java.io.IOException

fun File.safeCanonicalFile(): File =
    try {
        canonicalFile
    } catch (_: IOException) {
        absoluteFile
    }

val sanitizedRootBuildDir = rootProject.projectDir.safeCanonicalFile().resolve("build")

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
