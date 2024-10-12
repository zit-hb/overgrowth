//-----------------------------------------------------------------------------
//           Name: snow.as
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

const float kBaseSpawnRate = 120.0f;
bool spawnAlwaysOn = true;
float timePerSpawn = 1.0f / kBaseSpawnRate;

int playerInHotspotCount = 0;
float elapsedTime = 0.0f;
vec3 previousPosition = vec3(0.0f);

void SetParameters() {
    params.AddIntCheckbox("SpawnsOnlyWhenPlayerInside", false);
    spawnAlwaysOn = params.GetInt("SpawnsOnlyWhenPlayerInside") == 0;

    params.AddFloatSlider("SpawnRate", 1.0f, "min:0.01,max:2.0,step:0.01,text_mult:100");
    float spawnFrequency = Clamp(params.GetFloat("SpawnRate"), 0.01f, 10.0f);
    timePerSpawn = 1.0f / (kBaseSpawnRate * spawnFrequency);
}

void Update() {
    if (playerInHotspotCount <= 0 && !spawnAlwaysOn) {
        return;
    }
    SpawnSnowParticles();
}

void SpawnSnowParticles() {
    vec3 currentPosition = camera.GetPos();
    vec3 movementVector = currentPosition - previousPosition;
    elapsedTime += time_step;
    float domainSize = 5.0f;
    vec3 scale = vec3(domainSize);

    while (elapsedTime >= timePerSpawn) {
        vec3 offset;
        offset.x = RangedRandomFloat(-scale.x * 2.0f, scale.x * 2.0f);
        offset.y = RangedRandomFloat(-scale.y * 2.0f, scale.y * 2.0f);
        offset.z = RangedRandomFloat(-scale.z * 2.0f, scale.z * 2.0f);

        vec3 initialPosition = currentPosition + offset + movementVector * 150.0f;
        MakeParticle("Data/Particles/snow.xml", initialPosition, vec3(0.0f));
        elapsedTime -= timePerSpawn;
    }

    previousPosition = currentPosition;
}

void HandleEvent(string event, MovementObject@ mo) {
    Object@ moObj = ReadObjectFromID(mo.GetID());
    if (!moObj.GetPlayer()) {
        return;
    }
    if (event == "enter") {
        ++playerInHotspotCount;
    } else if (event == "exit") {
        --playerInHotspotCount;
    }
}

float Clamp(float value, float minValue, float maxValue) {
    return min(max(value, minValue), maxValue);
}
