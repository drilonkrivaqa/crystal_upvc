import java.io.File
import java.io.IOException

fun File.safeCanonicalFile(): File {
    val canonical = try {
        canonicalFile
    } catch (_: IOException) {
        absoluteFile
    }

    if (!System.getProperty("os.name", "").startsWith("Windows")) {
        return canonical
    }

    val shortPath = runCatching {
        val process = ProcessBuilder(
            "cmd",
            "/c",
            "for %I in (\"${canonical.path}\") do @echo %~sI"
        )
            .redirectErrorStream(true)
            .start()
            .apply { waitFor() }

        process.inputStream.bufferedReader().use { it.readLine() }
            ?.takeIf { it.isNotBlank() }
    }.getOrNull()

    return shortPath?.let { File(it) } ?: canonical
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
