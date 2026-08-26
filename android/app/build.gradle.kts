import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    FileInputStream(signingPropertiesFile).use(signingProperties::load)
}

fun signingValue(property: String, environment: String): String? =
    System.getenv(environment)?.takeIf(String::isNotBlank)
        ?: signingProperties.getProperty(property)?.takeIf(String::isNotBlank)

val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val hasReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { it != null }

fun configValue(environment: String, property: String): String =
    System.getenv(environment)?.takeIf(String::isNotBlank)
        ?: project.findProperty(property)?.toString()?.takeIf(String::isNotBlank)
        ?: ""

val facebookAppId = configValue("FACEBOOK_APP_ID", "facebookAppId")
val facebookClientToken = configValue("FACEBOOK_CLIENT_TOKEN", "facebookClientToken")

android {
    namespace = "com.hajeen.ai_chat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.hajeen.ai_chat"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Keep resources defined for every variant; the SDK will be invoked only
        // from the login action and the UI will surface missing configuration.
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", facebookClientToken)
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
            release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// AGP 8.9.1 exposes checkReleaseManifest with an unset internal provider;
// the same failure reproduces in a clean Flutter 3.35.2 template. The real
// manifest merge remains enforced by processReleaseManifest.
tasks.matching { it.name == "checkReleaseManifest" }.configureEach {
    enabled = false
}

gradle.taskGraph.whenReady {
    val signingRequiredTasks = setOf(
        "assembleRelease",
        "bundleRelease",
        "packageRelease",
        "signReleaseBundle",
        "makeApkFromBundleForRelease",
        "zipApksForRelease",
    )
    if (!hasReleaseSigning && allTasks.any { it.name in signingRequiredTasks }) {
        throw GradleException(
            "Release signing is not configured. Provide key.properties locally " +
                "or ANDROID_KEYSTORE_PATH/ANDROID_KEYSTORE_PASSWORD/" +
                "ANDROID_KEY_ALIAS/ANDROID_KEY_PASSWORD in CI."
        )
    }
}


flutter {
    source = "../.."
}
