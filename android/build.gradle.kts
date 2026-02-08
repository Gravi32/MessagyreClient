import com.android.build.gradle.AppExtension
import com.android.build.gradle.LibraryExtension
import org.gradle.api.tasks.Delete

plugins {
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.3" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Tutto il fix Android in un solo afterEvaluate
subprojects {
    afterEvaluate {
        extensions.findByType(AppExtension::class.java)?.apply {
            compileSdkVersion(36)
            buildToolsVersion("36.0.0")
            if (namespace.isNullOrEmpty()) namespace = project.group.toString()
        }

        extensions.findByType(LibraryExtension::class.java)?.apply {
            compileSdkVersion(36)
            buildToolsVersion("36.0.0")
            if (namespace.isNullOrEmpty()) namespace = project.group.toString()
        }
    }
}

// Clean task globale
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
