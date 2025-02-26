const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const app = express();
const port = process.env.PORT || 3000; // Render uses PORT env var

app.use(express.json());
app.use('/downloads', express.static('apks')); // Serve APK files statically

// Directory setup
const BASE_DIR = './generated_apps';
const APK_DIR = './apks';
const TEMPLATE_DIR = './templates';

// Ensure directories exist at startup
(async () => {
    await fs.mkdir(BASE_DIR, { recursive: true });
    await fs.mkdir(APK_DIR, { recursive: true });
})();

// Environment setup for Gradle (configured for Render's Docker environment)
const env = {
    ...process.env,
    ANDROID_HOME: process.env.ANDROID_HOME || '/usr/local/android-sdk',
    JAVA_HOME: process.env.JAVA_HOME || '/usr/lib/jvm/java-17-openjdk',
    PATH: `${process.env.PATH}:/usr/local/android-sdk/platform-tools:/usr/local/android-sdk/cmdline-tools/latest/bin`
};

// Endpoint to create a new Android app
app.post('/api/create-app', async (req, res) => {
    try {
        const { appName, packageName } = req.body;
        if (!appName || !packageName) {
            throw new Error('appName and packageName are required');
        }

        const projectId = `${appName}_${Date.now()}`;
        const projectDir = `${BASE_DIR}/${projectId}`;
        
        // Create project directory and copy template
        await fs.mkdir(projectDir, { recursive: true });
        await copyTemplate(TEMPLATE_DIR, projectDir);
        await generateAndroidFiles(projectDir, appName, packageName);

        // Build APK
        const apkPath = await buildApk(projectDir);
        const apkFileName = `${projectId}.apk`;
        const finalApkPath = `${APK_DIR}/${apkFileName}`;

        // Move APK to download directory and clean up
        await fs.rename(apkPath, finalApkPath);
        await fs.rm(projectDir, { recursive: true, force: true });

        res.json({ 
            success: true, 
            downloadUrl: `/downloads/${apkFileName}`,
            projectId
        });
    } catch (error) {
        console.error('Create app error:', error);
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to modify an existing app
app.post('/api/modify-app', async (req, res) => {
    try {
        const { projectId, xmlConfig, appName, packageName } = req.body;
        if (!projectId || !xmlConfig || !appName || !packageName) {
            throw new Error('projectId, xmlConfig, appName, and packageName are required');
        }

        const projectDir = `${BASE_DIR}/${projectId}`;
        
        // Recreate project if it doesn't exist
        if (!(await fs.stat(projectDir).catch(() => false))) {
            await fs.mkdir(projectDir, { recursive: true });
            await copyTemplate(TEMPLATE_DIR, projectDir);
            await generateAndroidFiles(projectDir, appName, packageName);
        }

        // Update layout and rebuild
        await updateLayout(projectDir, xmlConfig);
        const apkPath = await buildApk(projectDir);
        const apkFileName = `${projectId}.apk`;
        const finalApkPath = `${APK_DIR}/${apkFileName}`;
        
        await fs.rename(apkPath, finalApkPath);

        res.json({ 
            success: true, 
            downloadUrl: `/downloads/${apkFileName}` 
        });
    } catch (error) {
        console.error('Modify app error:', error);
        res.status(500).json({ error: error.message });
    }
});

// Helper function to copy template files
async function copyTemplate(source, destination) {
    const ncp = require('ncp').ncp;
    return new Promise((resolve, reject) => {
        ncp(source, destination, { clobber: true }, (err) => {
            if (err) reject(err);
            else resolve();
        });
    });
}

// Helper function to generate Android files
async function generateAndroidFiles(projectDir, appName, packageName) {
    const kotlinContent = `
package ${packageName}

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }
}
    `;
    
    const packagePath = `${projectDir}/app/src/main/java/${packageName.replace(/\./g, '/')}`;
    await fs.mkdir(packagePath, { recursive: true });
    await fs.writeFile(`${packagePath}/MainActivity.kt`, kotlinContent);

    // Update AndroidManifest.xml
    const manifestPath = `${projectDir}/app/src/main/AndroidManifest.xml`;
    let manifest = await fs.readFile(manifestPath, 'utf8');
    manifest = manifest.replace(/package="[^"]*"/, `package="${packageName}"`);
    await fs.writeFile(manifestPath, manifest);

    // Update app name in strings.xml
    const stringsPath = `${projectDir}/app/src/main/res/values/strings.xml`;
    let strings = await fs.readFile(stringsPath, 'utf8');
    strings = strings.replace(/<string name="app_name">[^<]*<\/string>/, 
        `<string name="app_name">${appName}</string>`);
    await fs.writeFile(stringsPath, strings);
}

// Helper function to update layout with XML
async function updateLayout(projectDir, xmlConfig) {
    const layoutPath = `${projectDir}/app/src/main/res/layout/activity_main.xml`;
    await fs.writeFile(layoutPath, xmlConfig);
}

// Helper function to build APK using Gradle
async function buildApk(projectDir) {
    return new Promise((resolve, reject) => {
        const gradleCmd = process.platform === 'win32' ? 'gradlew.bat' : './gradlew';
        const cmd = `cd ${projectDir} && ${gradleCmd} assembleDebug`;
        
        exec(cmd, { env }, (error, stdout, stderr) => {
            if (error) {
                console.error('Gradle build error:', stderr);
                reject(new Error(`Build failed: ${stderr}`));
                return;
            }
            console.log('Build output:', stdout);
            const apkPath = `${projectDir}/app/build/outputs/apk/debug/app-debug.apk`;
            resolve(apkPath);
        });
    });
}

// Start the server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
    console.log('Environment setup:', {
        ANDROID_HOME: env.ANDROID_HOME,
        JAVA_HOME: env.JAVA_HOME
    });
});