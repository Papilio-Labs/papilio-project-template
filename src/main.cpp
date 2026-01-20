/**
 * Papilio RetroCade - Wishbone Auto-Builder Template
 * ESP32-S3 + FPGA
 * 
 * This template is ready for the Papilio Automatic Library Builder.
 * Add Papilio Wishbone libraries to platformio.ini lib_deps and they will be
 * automatically integrated into this firmware.
 * 
 * The PAPILIO_AUTO_* marker regions are auto-generated - do not edit them manually.
 * Your custom code outside the markers will be preserved.
 * 
 * Hardware:
 * - ESP32-S3 SuperMini
 * - Gowin GW2A-18 FPGA (Papilio RetroCade)
 * 
 * Communication:
 * - SPI interface provides Wishbone bus access to FPGA peripherals
 */

//# PAPILIO_AUTO_INCLUDES_BEGIN
// Auto-generated library includes
// Library headers will appear here when you add Papilio libraries to lib_deps
//# PAPILIO_AUTO_INCLUDES_END

#include <Arduino.h>
#include <PapilioOS.h>

//# PAPILIO_AUTO_GLOBALS_BEGIN
// Auto-generated global objects
// Peripheral instances will be declared here when you add Papilio libraries to lib_deps
//# PAPILIO_AUTO_GLOBALS_END

// Your global variables go here
unsigned long lastPrint = 0;

void setup() {
    // Initialize serial for debugging
    Serial.begin(115200);
    delay(1000);
    
    Serial.println("\n\n");
    Serial.println("===========================================");
    Serial.println("  Papilio RetroCade - Wishbone System");
    Serial.println("===========================================");
    Serial.println();
    Serial.println("Ready to add Papilio Wishbone libraries!");
    Serial.println("Add libraries to platformio.ini lib_deps");
    Serial.println("and they will be auto-integrated.");
    Serial.println();
    
    //# PAPILIO_AUTO_INIT_BEGIN
    // Auto-generated initialization code
    // Peripheral initialization will appear here when you add Papilio libraries to lib_deps
    //# PAPILIO_AUTO_INIT_END
    
    // Initialize Papilio OS (CLI framework)
    PapilioOS.begin();
    
    Serial.println("Setup complete!\n");
}

void loop() {
    // Process Papilio OS (handles CLI commands)
    PapilioOS.handle();
    
    // Status update every second (only when not in CLI mode)
    if (!PapilioOS.isInCLIMode() && millis() - lastPrint > 1000) {
        lastPrint = millis();
        Serial.print("Running... [");
        Serial.print(millis() / 1000);
        Serial.println("s]");
    }
    
    //# PAPILIO_AUTO_CLI_BEGIN
    // Auto-generated CLI dispatcher
    // CLI command handling will appear here when you add libraries with CLI support
    //# PAPILIO_AUTO_CLI_END
    
    delay(10);
}
