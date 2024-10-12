//-----------------------------------------------------------------------------
//           Name: water_bob.as
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

float translationScale;
float rotationScale;
float timeScale;

array<int> objectIds;
array<vec3> originalTranslations;
array<quaternion> originalRotations;

void SetParameters() {
    params.AddString("Objects", "");
    params.AddFloatSlider("translation_scale", 4.0f, "min:0,max:5,step:0.001");
    params.AddFloatSlider("rotation_scale", 2.0f, "min:0,max:5,step:0.001");
    params.AddFloatSlider("time_scale", 0.2f, "min:0,max:2,step:0.001");

    translationScale = params.GetFloat("translation_scale");
    rotationScale = params.GetFloat("rotation_scale");
    timeScale = params.GetFloat("time_scale");

    InitializeObjects();
}

void InitializeObjects() {
    objectIds.resize(0);
    originalTranslations.resize(0);
    originalRotations.resize(0);

    TokenIterator tokenIter;
    tokenIter.Init();
    string objectsStr = params.GetString("Objects");

    while (tokenIter.FindNextToken(objectsStr)) {
        int objectId = atoi(tokenIter.GetToken(objectsStr));
        if (!ObjectExists(objectId)) {
            continue;
        }
        Object@ obj = ReadObjectFromID(objectId);
        objectIds.insertLast(objectId);
        originalTranslations.insertLast(obj.GetTranslation());
        originalRotations.insertLast(obj.GetRotation());
    }
}

void Update() {
    for (uint i = 0; i < objectIds.length(); ++i) {
        int objectId = objectIds[i];
        if (!ObjectExists(objectId)) {
            continue;
        }
        Object@ obj = ReadObjectFromID(objectId);
        vec3 originalTranslation = originalTranslations[i];
        quaternion originalRotation = originalRotations[i];

        ApplyBobEffect(obj, originalTranslation, originalRotation);
    }
}

void ApplyBobEffect(Object@ obj, const vec3& in originalTranslation, const quaternion& in originalRotation) {
    float currentTime = the_time * timeScale;
    float bobOffset = (sin(currentTime) * 0.01f + sin(currentTime * 2.7f) * 0.015f + sin(currentTime * 4.3f) * 0.008f) * translationScale;
    vec3 newPosition = originalTranslation;
    newPosition.y += bobOffset;
    obj.SetTranslation(newPosition);

    quaternion rotationX = quaternion(vec4(1, 0, 0, sin(currentTime * 3.0f) * 0.01f * rotationScale));
    quaternion rotationZ = quaternion(vec4(0, 0, 1, sin(currentTime * 3.7f) * 0.01f * rotationScale));
    quaternion newRotation = rotationZ * rotationX * originalRotation;
    obj.SetRotation(newRotation);
}
