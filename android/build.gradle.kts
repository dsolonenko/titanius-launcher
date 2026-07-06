allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Fix for old Flutter plugins that don't have a namespace in their build.gradle.
    // AGP 8.x requires all modules to have a namespace.
    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        if (androidExtension != null) {
            val android = androidExtension as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                // Read namespace from AndroidManifest.xml package attribute
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val packageName = groovy.xml.XmlParser().parse(manifestFile).attribute("package") as? String
                    if (packageName != null) {
                        android.namespace = packageName
                    }
                }
            }

            // Fix JVM target inconsistency for old plugins that hardcode Java 1.8
            // while Kotlin defaults to a higher JVM target (e.g., 21).
            val jvmTarget = "17"
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
