pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

include(":app")

val flutterSdkPath = run {
    val properties = java.util.Properties()
    File(rootProject.projectDir, "local.properties").inputStream().use { stream -> properties.load(stream) }
    properties.getProperty("flutter.sdk") ?: error("flutter.sdk not set in local.properties")
}

includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

project(":app").projectDir = file("app")

settings.rootProject.name = "android"
