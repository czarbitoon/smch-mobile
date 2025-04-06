pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        // Add Flutter repository for resolving Flutter dependencies
        val flutterSdkPath = run {
            val properties = java.util.Properties()
            val localPropertiesFile = File(rootProject.projectDir, "local.properties")
            if (localPropertiesFile.exists()) {
                localPropertiesFile.inputStream().use { stream -> properties.load(stream) }
                properties.getProperty("flutter.sdk")
            } else {
                System.getenv("FLUTTER_SDK") ?: "C:\\flutter"
            }
        }
        maven {
            url = uri("${flutterSdkPath}/bin/cache/artifacts/engine/android-arm/")
            metadataSources {
                artifact()
            }
        }
        maven {
            url = uri("${flutterSdkPath}/bin/cache/artifacts/engine/android-arm64/")
            metadataSources {
                artifact()
            }
        }
        maven {
            url = uri("${flutterSdkPath}/bin/cache/artifacts/engine/android-x64/")
            metadataSources {
                artifact()
            }
        }
    }
}

include(":app")

val flutterSdkPath = run {
    val properties = java.util.Properties()
    val localPropertiesFile = File(rootProject.projectDir, "local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { stream -> properties.load(stream) }
        properties.getProperty("flutter.sdk")
    } else {
        System.getenv("FLUTTER_SDK") ?: "C:\\flutter"
    }
}

includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

project(":app").projectDir = file("app")

settings.rootProject.name = "android"
