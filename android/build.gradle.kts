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
}

// Ин бояд пеш аз `evaluationDependsOn(":app")` рӯй диҳад: он метавонад
// баҳодиҳии ":app"-ро дарҳол маҷбур кунад, ва пас аз баҳодиҳӣ дигар
// `afterEvaluate` рӯи он даъват кардан мумкин нест ("already evaluated").
// Баъзе плагинҳои сеюмшахс (масалан agora_rtc_engine) ҳанӯз бо compileSdk-и
// кӯҳна (31) меоянд, ки бо androidx-и навтарин (34+ талаб мекунад) мухолифат
// мекунад ва checkReleaseAarMetadata-ро вайрон мекунад. Аммо баъзе плагинҳои
// дигар (масалан permission_handler_android) аллакай бо compileSdk 37 худашон
// эълон мекунанд (барои рамзҳои SDK-и нав), бинобар ин бояд ФАҚАТ баланд
// кунем (ҳеҷ гоҳ паст накунем) — ба ҷои маҷбур кардани як адади собит.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.withGroovyBuilder {
            val current = getProperty("compileSdk") as? Int ?: 0
            if (current < 37) {
                setProperty("compileSdk", 37)
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
