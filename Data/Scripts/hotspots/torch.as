//-----------------------------------------------------------------------------
//           Name: torch.as
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

int lightId = -1;
int lampId = -1;
bool isInitialized = false;

void Init() {
    SetHotspotScale(0.5f);
}

void Update() {
    if (!isInitialized) {
        InitializeTorch();
        isInitialized = true;
    }

    if (lampId == -1 || !ObjectExists(lampId)) {
        CreateTorch();
        return;
    }

    if (lightId == -1 || !ObjectExists(lightId)) {
        Print("No flame hotspot found\n");
        return;
    }

    UpdateLightPosition();
}

void InitializeTorch() {
    FindSavedTorch();
    FindFlameHotspot();
}

void SetHotspotScale(float scale) {
    Object@ hotspotObj = ReadObjectFromID(hotspot.GetID());
    hotspotObj.SetScale(scale);
}

void CreateTorch() {
    lampId = CreateObject("Data/Items/torch.xml", false);
    Object@ lampObj = ReadObjectFromID(lampId);
    ScriptParams@ lampParams = lampObj.GetScriptParams();
    lampParams.SetInt("BelongsTo", hotspot.GetID());

    Object@ hotspotObj = ReadObjectFromID(hotspot.GetID());
    lampObj.SetTranslation(hotspotObj.GetTranslation());
    lampObj.SetSelectable(true);
    lampObj.SetTranslatable(true);
}

void FindSavedTorch() {
    array<int>@ itemIds = GetObjectIDsType(_item_object);
    for (uint i = 0; i < itemIds.length(); ++i) {
        Object@ obj = ReadObjectFromID(itemIds[i]);
        ScriptParams@ objParams = obj.GetScriptParams();
        if (objParams.HasParam("BelongsTo") && objParams.GetInt("BelongsTo") == hotspot.GetID()) {
            lampId = itemIds[i];
            return;
        }
    }
}

void FindFlameHotspot() {
    array<int>@ hotspotIds = GetObjectIDsType(_hotspot_object);
    for (uint i = 0; i < hotspotIds.length(); ++i) {
        Object@ obj = ReadObjectFromID(hotspotIds[i]);
        ScriptParams@ objParams = obj.GetScriptParams();
        if (!objParams.HasParam("FlameTaken")) {
            continue;
        }
        int flameTaken = objParams.GetInt("FlameTaken");
        if (flameTaken == 0 || flameTaken == hotspot.GetID()) {
            objParams.SetInt("FlameTaken", hotspot.GetID());
            lightId = hotspotIds[i];
            return;
        }
    }
}

void UpdateLightPosition() {
    ItemObject@ torchItem = ReadItemID(lampId);
    Object@ lightObj = ReadObjectFromID(lightId);
    mat4 torchTransform = torchItem.GetPhysicsTransform();
    quaternion torchRotation = QuaternionFromMat4(torchTransform.GetRotationPart());
    vec3 newPosition = torchItem.GetPhysicsPosition() + (torchRotation * vec3(0.0f, 0.35f, 0.0f)) + vec3(0.0f, -0.25f, 0.0f);
    lightObj.SetTranslation(newPosition);
}
