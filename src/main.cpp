#include <Arduino.h>
#include <PapilioOS.h>
#include <WishboneSPI.h>

namespace {
constexpr int kSpiClock = 1;
constexpr int kSpiMiso = 4;
constexpr int kSpiMosi = 2;
constexpr int kSpiChipSelect = 3;

SPIClass fpgaSPI;
unsigned long lastPrint = 0;
}

void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println("\nPapilio RetroCade - Wishbone System");

    fpgaSPI.begin(kSpiClock, kSpiMiso, kSpiMosi, kSpiChipSelect);
    wishboneInit(&fpgaSPI, kSpiChipSelect);

    PapilioOS.begin();
    Serial.println("Setup complete!");
}

void loop() {
    PapilioOS.handle();

    if (!PapilioOS.isInCLIMode() && millis() - lastPrint >= 1000) {
        lastPrint = millis();
        Serial.printf("Running... [%lus]\n", lastPrint / 1000);
    }

    delay(10);
}
