//-----------------------------------------------------------------------------
//           Name: wet_cube.as
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

int waterSurfaceId = -1;
int waterDecalId = -1;

void SetParameters() {
    params.AddFloatSlider("Wave Density", 0.25f, "min:0,max:1,step:0.01");
    params.AddFloatSlider("Wave Height", 0.5f, "min:0,max:1,step:0.01");
    params.AddFloatSlider("Water Fog", 1.0f, "min:0,max:1,step:0.01");
}

void Dispose() {
    DeleteObjectById(waterDecalId);
    DeleteObjectById(waterSurfaceId);
}

void Update() {
    UpdateWaterSurface();
    UpdateWaterDecal();
    HandleCollisions();
}

void UpdateWaterSurface() {
    if (params.HasParam("Invisible")) {
        return;
    }
    if (waterSurfaceId == -1) {
        waterSurfaceId = CreateObject("Data/Objects/water_test.xml", true);
    }
    Object@ waterSurfaceObj = ReadObjectFromID(waterSurfaceId);
    Object@ hotspotObj = ReadObjectFromID(hotspot.GetID());
    waterSurfaceObj.SetTranslation(hotspotObj.GetTranslation());
    waterSurfaceObj.SetRotation(hotspotObj.GetRotation());
    waterSurfaceObj.SetScale(hotspotObj.GetScale() * 2.0f);

    vec3 tint = vec3(params.GetFloat("Wave Height"), params.GetFloat("Wave Density"), params.GetFloat("Water Fog"));
    waterSurfaceObj.SetTint(tint);
}

void UpdateWaterDecal() {
    if (waterDecalId == -1) {
        waterDecalId = CreateObject("Data/Objects/Decals/water_fog.xml", true);
    }
    Object@ waterDecalObj = ReadObjectFromID(waterDecalId);
    Object@ hotspotObj = ReadObjectFromID(hotspot.GetID());
    waterDecalObj.SetTranslation(hotspotObj.GetTranslation());
    waterDecalObj.SetRotation(hotspotObj.GetRotation());
    waterDecalObj.SetScale(hotspotObj.GetScale() * 4.0f);
}

void HandleCollisions() {
    array<int> collidingObjects;
    level.GetCollidingObjects(hotspot.GetID(), collidingObjects);
    for (uint i = 0; i < collidingObjects.length(); ++i) {
        int objectId = collidingObjects[i];
        if (!ObjectExists(objectId)) {
            continue;
        }
        Object@ obj = ReadObjectFromID(objectId);
        if (obj.GetType() != _movement_object) {
            continue;
        }
        MovementObject@ mo = ReadCharacterID(objectId);
        mo.Execute("WaterIntersect(" + hotspot.GetID() + ");");
        if (params.HasParam("Lethal")) {
            mo.Execute("zone_killed=1; TakeDamage(1.0f);");
        }
    }
}

void DeleteObjectById(int& inout objectId) {
    if (objectId != -1) {
        QueueDeleteObjectID(objectId);
        objectId = -1;
    }
}
