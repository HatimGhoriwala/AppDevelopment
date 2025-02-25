const express = require("express");
const multer = require("multer");
const { exec } = require("child_process");
const path = require("path");
const fs = require("fs");

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware to parse JSON
app.use(express.json());

// Configure Multer to handle XML uploads
const upload = multer({ dest: "uploads/" });

// 🔹 API to receive XML file from frontend
app.post("/upload-xml", upload.single("xmlFile"), (req, res) => {
    if (!req.file) {
        return res.status(400).send("No XML file uploaded.");
    }

    const xmlPath = path.join(__dirname, req.file.path);
    const androidXmlPath = path.join(__dirname, "android-project", "app", "src", "main", "res", "values", "strings.xml");

    // Replace the old XML with the new one
    fs.copyFile(xmlPath, androidXmlPath, (err) => {
        if (err) return res.status(500).send("Error updating XML: " + err);
        
        // Run Gradle build
        exec("./gradlew assembleDebug", { cwd: "./android-project" }, (error, stdout, stderr) => {
            if (error) {
                console.error("Gradle Build Error:", stderr);
                return res.status(500).send("Build failed: " + stderr);
            }
            
            console.log("Build Success:", stdout);
            const apkPath = path.join(__dirname, "android-project", "app", "build", "outputs", "apk", "debug", "app-debug.apk");
            return res.send({ message: "Build successful!", apk: "/download-apk" });
        });
    });
});

// 🔹 API to download the built APK
app.get("/download-apk", (req, res) => {
    const apkPath = path.join(__dirname, "android-project", "app", "build", "outputs", "apk", "debug", "app-debug.apk");

    if (fs.existsSync(apkPath)) {
        return res.download(apkPath);
    } else {
        return res.status(404).send("APK not found. Try rebuilding.");
    }
});

// Start Server
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
