//-----------------------------------------------------------------------------
//           Name: rain.as
//      Developer: Wolfire Games LLC
//    Script Type: Hotspot
//-----------------------------------------------------------------------------
//
//   Copyright 2022 Wolfire Games LLC
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
//-----------------------------------------------------------------------------

float lightningTime = -1.0f;
float nextLightningTime = -1.0f;
float thunderTime = -1.0f;
float lightningDistance = 0.0f;

vec3 originalSunPosition;
vec3 originalSunColor;
float originalSunAmbient;

void Init() {
    originalSunPosition = GetSunPosition();
    originalSunColor = GetSunColor();
    originalSunAmbient = GetSunAmbient();
}

void Dispose() {
    RestoreSunSettings();
}

void Update() {
    if (nextLightningTime < the_time) {
        ScheduleNextLightning();
    }
    if (thunderTime != -1.0f && thunderTime < the_time) {
        PlayThunderSound();
        thunderTime = -1.0f;
    }
    if (lightningTime <= the_time) {
        UpdateLightningEffects();
    }
}

void ScheduleNextLightning() {
    nextLightningTime = the_time + RangedRandomFloat(6.0f, 12.0f);
    lightningDistance = RangedRandomFloat(0.0f, 1.0f);
    thunderTime = the_time + lightningDistance * 3.0f;
    lightningTime = the_time;
    SetSunPosition(RandomLightningPosition());
}

vec3 RandomLightningPosition() {
    float x = RangedRandomFloat(-1.0f, 1.0f);
    float y = RangedRandomFloat(0.5f, 1.0f);
    float z = RangedRandomFloat(-1.0f, 1.0f);
    return normalize(vec3(x, y, z));
}

void PlayThunderSound() {
    if (lightningDistance < 0.3f) {
        PlaySoundGroup("Data/Sounds/weather/thunder_strike_mike_koenig.xml");
    } else {
        PlaySoundGroup("Data/Sounds/weather/tapio/thunder.xml");
    }
}

void UpdateLightningEffects() {
    float flashAmount = Clamp(1.0f + (lightningTime - the_time) * 0.1f, 0.0f, 1.0f);
    SetSunAmbient(1.5f);

    flashAmount = Clamp(1.0f + (lightningTime - the_time) * 2.0f, 0.0f, 1.0f);
    flashAmount *= RangedRandomFloat(0.8f, 1.2f) * 3.0f;

    vec3 skyTint = mix(GetBaseSkyTint() * 0.7f, vec3(3.0f), flashAmount);
    SetSkyTint(skyTint);

    SetSunColor(vec3(flashAmount) * 4.0f);
    SetFlareDiffuse(4.0f);
}

void RestoreSunSettings() {
    SetSunAmbient(originalSunAmbient);
    SetSkyTint(GetBaseSkyTint());
    SetSunColor(originalSunColor);
    SetSunPosition(originalSunPosition);
}

float Clamp(float value, float minValue, float maxValue) {
    return min(max(value, minValue), maxValue);
}
