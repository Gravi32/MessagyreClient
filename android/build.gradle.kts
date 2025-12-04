plugins {
    // Only apply non-Android plugins here
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.3" apply false
}

// Repositories for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Move the main build directory outside android folder
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Ensure subprojects are evaluated after :app
subprojects {
    project.evaluationDependsOn(":app")
}

// Optional: global clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
