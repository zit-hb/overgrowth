//-----------------------------------------------------------------------------
//           Name: water_bob_fast.as
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

const float kTranslationDefaultScale = 4.0f;
const float kRotationDefaultScale = 2.0f;
const float kTimeDefaultScale = 0.2f;
const float kTranslationMinScale = 0.0f;
const float kTranslationMaxScale = 5.0f;
const float kRotationMinScale = 0.0f;
const float kRotationMaxScale = 5.0f;
const float kTimeMinScale = 0.0f;
const float kTimeMaxScale = 2.0f;

float translationScale;
float rotationScale;
float timeScale;

array<int> targetObjectIds;
array<vec3> originalTranslations;
array<quaternion> originalRotations;

bool reloadTargetsQueued = true;
bool isEditorEnabled = false;
string newConnectionObjectIdInput;
bool newConnectionObjectIdValid = false;
bool newConnectionObjectIdInputWasFocused = false;

void SetParameters() {
    params.AddFloatSlider("translation_scale", kTranslationDefaultScale, "min:" + kTranslationMinScale + ",max:" + kTranslationMaxScale + ",step:0.001");
    params.AddFloatSlider("rotation_scale", kRotationDefaultScale, "min:" + kRotationMinScale + ",max:" + kRotationMaxScale + ",step:0.001");
    params.AddFloatSlider("time_scale", kTimeDefaultScale, "min:" + kTimeMinScale + ",max:" + kTimeMaxScale + ",step:0.001");

    translationScale = params.GetFloat("translation_scale");
    rotationScale = params.GetFloat("rotation_scale");
    timeScale = params.GetFloat("time_scale");

    ReloadTargets();
}

void ReloadTargets() {
    targetObjectIds.resize(0);
    originalTranslations.resize(0);
    originalRotations.resize(0);

    array<int> connectedObjectIds = hotspot.GetConnectedObjects();

    if (params.HasParam("Objects")) {
        TokenIterator tokenIter;
        tokenIter.Init();
        string objectsStr = params.GetString("Objects");

        while (tokenIter.FindNextToken(objectsStr)) {
            int objectId = atoi(tokenIter.GetToken(objectsStr));
            if (ObjectExists(objectId) && connectedObjectIds.find(objectId) == -1) {
                Object@ obj = ReadObjectFromID(objectId);
                hotspot.ConnectTo(obj);
                connectedObjectIds.insertLast(objectId);
            }
        }
        params.Remove("Objects");
    }

    for (uint i = 0; i < connectedObjectIds.length(); ++i) {
        int objectId = connectedObjectIds[i];
        if (!ObjectExists(objectId)) {
            continue;
        }
        Object@ obj = ReadObjectFromID(objectId);
        targetObjectIds.insertLast(objectId);

        vec3 origTranslation;
        quaternion origRotation;

        if (!params.HasParam("SavedTransform" + objectId)) {
            origTranslation = obj.GetTranslation();
            origRotation = obj.GetRotation();
            SaveTransform(objectId, origTranslation, origRotation);
        } else {
            LoadSavedTransform(objectId, origTranslation, origRotation);
        }

        originalTranslations.insertLast(origTranslation);
        originalRotations.insertLast(origRotation);
    }
}

void SaveTransform(int objectId, const vec3& in translation, const quaternion& in rotation) {
    string transformStr = translation.x + " " + translation.y + " " + translation.z + " "
                        + rotation.x + " " + rotation.y + " " + rotation.z + " " + rotation.w;
    params.AddString("SavedTransform" + objectId, transformStr);
}

void LoadSavedTransform(int objectId, vec3& out translation, quaternion& out rotation) {
    string transformStr = params.GetString("SavedTransform" + objectId);
    TokenIterator tokenIter;
    tokenIter.Init();

    if (!tokenIter.FindNextToken(transformStr)) return;
    translation.x = atof(tokenIter.GetToken(transformStr));
    if (!tokenIter.FindNextToken(transformStr)) return;
    translation.y = atof(tokenIter.GetToken(transformStr));
    if (!tokenIter.FindNextToken(transformStr)) return;
    translation.z = atof(tokenIter.GetToken(transformStr));
    if (!tokenIter.FindNextToken(transformStr)) return;
    rotation.x = atof(tokenIter.GetToken(transformStr));
    if (!tokenIter.FindNextToken(transformStr)) return;
    rotation.y = atof(tokenIter.GetToken(transformStr));
    if (!tokenIter.FindNextToken(transformStr)) return;
    rotation.z = atof(tokenIter.GetToken(transformStr));
    if (!tokenIter.FindNextToken(transformStr)) return;
    rotation.w = atof(tokenIter.GetToken(transformStr));
}

void PreDraw(float currGameTime) {
    if (reloadTargetsQueued) {
        ReloadTargets();
        reloadTargetsQueued = false;
    }

    for (uint i = 0; i < targetObjectIds.length(); ++i) {
        int objectId = targetObjectIds[i];
        if (!ObjectExists(objectId)) {
            continue;
        }
        Object@ obj = ReadObjectFromID(objectId);
        vec3 origTranslation = originalTranslations[i];
        quaternion origRotation = originalRotations[i];

        ApplyBobEffect(obj, origTranslation, origRotation, currGameTime, objectId);
    }
}

void ApplyBobEffect(Object@ obj, const vec3& in origTranslation, const quaternion& in origRotation, float currGameTime, int objectId) {
    float currYTranslation = (
        sin(currGameTime * timeScale + objectId) * 0.01f +
        sin(currGameTime * 2.7f * timeScale + objectId) * 0.015f +
        sin(currGameTime * 4.3f * timeScale + objectId) * 0.008f
    ) * translationScale;

    quaternion rotationX = quaternion(vec4(1, 0, 0, sin(currGameTime * 3.0f * timeScale + objectId) * 0.01f * rotationScale));
    quaternion rotationZ = quaternion(vec4(0, 0, 1, sin(currGameTime * 3.7f * timeScale + objectId) * 0.01f * rotationScale));
    quaternion newRotation = rotationZ * rotationX * origRotation;

    vec3 newPosition = origTranslation;
    newPosition.y += currYTranslation;
    obj.SetTranslationRotationFast(newPosition, newRotation);
}

void DrawEditor() {
    if (!isEditorEnabled) {
        return;
    }

    bool isUpdated = false;
    int hotspotId = hotspot.GetID();
    Object@ hotspotObj = ReadObjectFromID(hotspotId);

    ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(440, 250));
    ImGui_Begin("Water Bob Hotspot - id: " + hotspotId, isEditorEnabled);

    ImGui_SameLine(ImGui_GetWindowWidth() - 60.0f);
    if (ImGui_SmallButton("Help")) {
        ImGui_SetTooltip(
            "Select hotspot then ALT-click to connect to other objects.\n"
            "Connected objects will bob like they are on top of water.\n"
            "To water-bob groups or prefabs, see manual connect UI below."
        );
    }

    ImGui_Text("Properties:");

    float newTranslationScale = translationScale;
    if (ImGui_SliderFloat("Translation Scale", newTranslationScale, kTranslationMinScale, kTranslationMaxScale)) {
        params.SetFloat("translation_scale", newTranslationScale);
        isUpdated = true;
    }

    float newRotationScale = rotationScale;
    if (ImGui_SliderFloat("Rotation Scale", newRotationScale, kRotationMinScale, kRotationMaxScale)) {
        params.SetFloat("rotation_scale", newRotationScale);
        isUpdated = true;
    }

    float newTimeScale = timeScale;
    if (ImGui_SliderFloat("Time Scale", newTimeScale, kTimeMinScale, kTimeMaxScale)) {
        params.SetFloat("time_scale", newTimeScale);
        isUpdated = true;
    }

    ImGui_NewLine();
    ImGui_Separator();
    ImGui_NewLine();

    ImGui_PushItemWidth(150.0f);
    if (ImGui_InputText("Connect group or prefab with Object Id", newConnectionObjectIdInput, 7, ImGuiInputTextFlags_CharsDecimal)) {
        int newObjectId = atoi(newConnectionObjectIdInput);
        newConnectionObjectIdValid = IsValidConnection(newObjectId);
    }
    ImGui_PopItemWidth();

    bool connectTriggered = false;
    if (ImGui_Button("Connect")) {
        connectTriggered = true;
    }

    if (connectTriggered && newConnectionObjectIdValid) {
        int newObjectId = atoi(newConnectionObjectIdInput);
        hotspot.ConnectTo(ReadObjectFromID(newObjectId));
        newConnectionObjectIdInput = "";
        newConnectionObjectIdValid = false;
        reloadTargetsQueued = true;
    }

    if (!newConnectionObjectIdValid && newConnectionObjectIdInput != "") {
        ImGui_TextColored(vec4(1.0f, 0.5f, 0.0f, 1.0f), "Invalid Object ID");
    }

    DisplayConnectedObjects();

    ImGui_End();
    ImGui_PopStyleVar();

    if (isUpdated) {
        SetParameters();
    }
}

bool IsValidConnection(int objectId) {
    if (objectId == hotspot.GetID()) {
        return false;
    }
    if (!ObjectExists(objectId)) {
        return false;
    }
    Object@ obj = ReadObjectFromID(objectId);
    return AcceptConnectionsTo(obj);
}

void DisplayConnectedObjects() {
    array<int> connectedObjectIds = hotspot.GetConnectedObjects();

    ImGui_NewLine();
    ImGui_Text("Connected Objects:");
    ImGui_Indent();

    for (uint i = 0; i < connectedObjectIds.length(); ++i) {
        int objectId = connectedObjectIds[i];
        ImGui_Text("Object " + objectId);
        ImGui_SameLine();
        if (ImGui_SmallButton("X###disconnect_" + i)) {
            hotspot.Disconnect(ReadObjectFromID(objectId));
            reloadTargetsQueued = true;
        }
    }

    if (connectedObjectIds.length() == 0) {
        ImGui_Text("None");
    }

    ImGui_Unindent();
}

bool AcceptConnectionsTo(Object@ other) {
    int otherType = other.GetType();
    return otherType == _env_object || otherType == _decal_object || otherType == _hotspot_object ||
           otherType == _group || otherType == _item_object || otherType == _ambient_sound_object ||
           otherType == _dynamic_light_object || otherType == _prefab;
}

void Dispose() {
    for (uint i = 0; i < targetObjectIds.length(); ++i) {
        int objectId = targetObjectIds[i];
        if (!ObjectExists(objectId)) {
            continue;
        }
        Object@ obj = ReadObjectFromID(objectId);
        ResetToSavedTransform(obj, objectId);
    }
}

void ResetToSavedTransform(Object@ obj, int objectId) {
    vec3 origTranslation;
    quaternion origRotation;
    if (params.HasParam("SavedTransform" + objectId)) {
        LoadSavedTransform(objectId, origTranslation, origRotation);
        obj.SetTranslationRotationFast(origTranslation, origRotation);
    }
}

void LaunchCustomGUI() {
    isEditorEnabled = true;
}

bool ObjectInspectorReadOnly() {
    return true;
}
