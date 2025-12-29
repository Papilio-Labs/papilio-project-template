/**
 * Papilio RetroCade Template Project
 * 
 * This template demonstrates:
 * - ESP32-S3 to FPGA communication via Wishbone SPI
 * - RGB LED control using WS2812B protocol
 * - Basic initialization and color cycling
 * 
 * Hardware:
 * - ESP32-S3 microcontroller
 * - Gowin GW5A-25A FPGA
 * - WS2812B RGB LED
 * 
 * Libraries:
 * - papilio_wishbone_spi_master: SPI-to-Wishbone bridge
 * - papilio_wishbone_rgb_led: RGB LED controller
 */

#include <Arduino.h>
#include <SPI.h>
#include "WishboneSPI.h"
#include "RGBLed.h"

// SPI pin definitions for Papilio RetroCade
// ESP32-S3 to FPGA SPI connection
#define SPI_CLK   12  // GPIO12 -> FPGA pin B12
#define SPI_MOSI  11  // GPIO11 -> FPGA pin B11
#define SPI_MISO  13  // GPIO13 -> FPGA pin C12
#define SPI_CS    10  // GPIO10 -> FPGA pin A9

// SPI interface handle
SPIClass *fpgaSPI = nullptr;

// Color cycle array
const uint32_t colors[] = {
    RGBLed::COLOR_RED,
    RGBLed::COLOR_GREEN,
    RGBLed::COLOR_BLUE,
    RGBLed::COLOR_YELLOW,
    RGBLed::COLOR_CYAN,
    RGBLed::COLOR_MAGENTA,
    RGBLed::COLOR_WHITE,
    RGBLed::COLOR_ORANGE,
    RGBLed::COLOR_PURPLE
};
const int numColors = sizeof(colors) / sizeof(colors[0]);
int currentColorIndex = 0;

void setup() {
    // Initialize serial for debugging
    Serial.begin(115200);
    delay(1000);
    
    Serial.println("\n\n");
    Serial.println("====================================");
    Serial.println("  Papilio RetroCade Template");
    Serial.println("  ESP32-S3 + Gowin FPGA");
    Serial.println("====================================");
    Serial.println();
    
    // Initialize SPI for FPGA communication
    Serial.println("Initializing SPI...");
    fpgaSPI = new SPIClass(HSPI);
    fpgaSPI->begin(SPI_CLK, SPI_MISO, SPI_MOSI, SPI_CS);
    
    pinMode(SPI_CS, OUTPUT);
    digitalWrite(SPI_CS, HIGH);
    
    Serial.println("  SPI initialized");
    Serial.printf("  CS:   GPIO%d\n", SPI_CS);
    Serial.printf("  CLK:  GPIO%d\n", SPI_CLK);
    Serial.printf("  MOSI: GPIO%d\n", SPI_MOSI);
    Serial.printf("  MISO: GPIO%d\n", SPI_MISO);
    Serial.println();
    
    // Initialize RGB LED library
    Serial.println("Initializing RGB LED...");
    RGBLed::begin(fpgaSPI, SPI_CS);
    Serial.println("  RGB LED initialized");
    Serial.println();
    
    // Set initial color
    Serial.println("Setting initial color: RED");
    RGBLed::setColor(RGBLed::COLOR_RED);
    
    Serial.println();
    Serial.println("Setup complete!");
    Serial.println("LED will cycle through colors every 2 seconds");
    Serial.println();
}

void loop() {
    static unsigned long lastChange = 0;
    
    // Change color every 2 seconds
    if (millis() - lastChange > 2000) {
        // Move to next color
        currentColorIndex = (currentColorIndex + 1) % numColors;
        
        // Set the new color
        RGBLed::setColor(colors[currentColorIndex]);
        
        // Print color name
        const char* colorNames[] = {
            "RED", "GREEN", "BLUE", "YELLOW",
            "CYAN", "MAGENTA", "WHITE", "ORANGE", "PURPLE"
        };
        Serial.print("Color: ");
        Serial.println(colorNames[currentColorIndex]);
        
        lastChange = millis();
    }
    
    delay(10);
}
