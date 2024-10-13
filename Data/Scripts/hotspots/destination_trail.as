//-----------------------------------------------------------------------------
//           Name: destination_trail.as
//      Developer: Wolfire Games LLC
//    Script Type: Hotspot
//        License: Read below
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

array<int> points;
string placeholder = "Data/Objects/placeholder/empty_placeholder.xml";
int pointIndex = 0;
int trailIndex = 0;
bool postInitDone = false;
vec3 trailPos = vec3(0);
float trailDistance = 0.0f;
const vec3 originOffset = vec3(0, -0.5f, 0);

void SetParameters() {
    params.AddInt("NumPoints", 4);
}

void Init() {
    // No additional initialization needed
}

void Dispose() {
    // Clean up if necessary
}

void HandleEventItem(string event, ItemObject @obj) {
    // No item event handling needed
}

void Reset() {
    pointIndex = 0;
    trailIndex = pointIndex;
}

void Update() {
    if (!postInitDone) {
        InitializePoints();
        postInitDone = true;
    }
    if (points.size() < 2) {
        AddPoint();
    }
    if (EditorModeActive()) {
        CheckForDeletedPoints();
        CheckForNewPoints();
        DrawConnectionLines();
        DrawBoxes();
    } else {
        CheckForPreviousPoint();
        CheckForNextPoint();
        UpdateTrail();
    }
}

void InitializePoints() {
    Object @hotspotObj = ReadObjectFromID(hotspot.GetID());
    hotspotObj.SetScale(vec3(0.125f));
    hotspotObj.SetCopyable(false);
    hotspotObj.SetDeletable(true);
    hotspotObj.SetSelectable(true);
    hotspotObj.SetTranslatable(true);
    hotspotObj.SetScalable(false);
    hotspotObj.SetRotatable(false);
    points.insertLast(hotspot.GetID());
    CheckForNewPoints();
}

void UpdateTrail() {
    MovementObject @player = ReadCharacter(0);
    Object @closestPointObj = ReadObjectFromID(points[trailIndex]);

    if (trailPos == vec3(0) || trailDistance > 10.0f) {
        trailPos = player.position + originOffset;
        trailIndex = pointIndex;
        trailDistance = 0.0f;
    }
    vec3 targetPos = closestPointObj.GetTranslation();
    vec3 direction = normalize(targetPos - trailPos);
    MakeParticle("Data/Particles/destination_particle.xml", trailPos, direction);
    trailPos += (direction * 0.05f);

    float radius = 0.1f;
    if (distance(trailPos, targetPos) < radius) {
        if (int(points.size()) > (trailIndex + 1)) {
            trailIndex++;
        } else {
            trailPos = player.position + originOffset;
            trailIndex = pointIndex;
            trailDistance = 0.0f;
        }
    }
}

void CheckForNextPoint() {
    if (int(points.size()) <= pointIndex + 1) {
        return;
    }
    MovementObject @player = ReadCharacter(0);
    Object @nextPoint = ReadObjectFromID(points[pointIndex + 1]);
    if (distance(player.position, nextPoint.GetTranslation()) < distanceBetweenPoints(pointIndex, pointIndex + 1)) {
        pointIndex++;
    }
}

void CheckForPreviousPoint() {
    if (pointIndex - 1 < 0) {
        return;
    }
    MovementObject @player = ReadCharacter(0);
    Object @previousPoint = ReadObjectFromID(points[pointIndex - 1]);
    if (distance(player.position, previousPoint.GetTranslation()) < distanceBetweenPoints(pointIndex, pointIndex - 1)) {
        pointIndex--;
    }
}

float distanceBetweenPoints(int indexA, int indexB) {
    Object @pointA = ReadObjectFromID(points[indexA]);
    Object @pointB = ReadObjectFromID(points[indexB]);
    return distance(pointA.GetTranslation(), pointB.GetTranslation());
}

void CheckForNewPoints() {
    array<int> placeholderIDs = GetObjectIDsType(35);
    for (uint o = 0; o < placeholderIDs.size(); o++) {
        if (points.find(placeholderIDs[o]) == -1) {
            Object @placeholder = ReadObjectFromID(placeholderIDs[o]);
            ScriptParams @placeholderParams = placeholder.GetScriptParams();
            if (placeholderParams.HasParam("belongsto") && placeholderParams.GetString("belongsto") == ("" + hotspot.GetID())) {
                points.insertLast(placeholderIDs[o]);
            }
        }
    }
}

void CheckForDeletedPoints() {
    for (uint i = 0; i < points.size(); i++) {
        if (!ObjectExists(points[i])) {
            points.removeAt(i);
            i--;
        }
    }
}

void DrawConnectionLines() {
    Object @hotspotObj = ReadObjectFromID(hotspot.GetID());
    vec3 lastPos = hotspotObj.GetTranslation();
    for (uint i = 0; i < points.size(); i++) {
        Object @thisPoint = ReadObjectFromID(points[i]);
        DebugDrawLine(lastPos, thisPoint.GetTranslation(), vec3(1), _delete_on_update);
        lastPos = thisPoint.GetTranslation();
    }
}

void DrawBoxes() {
    Object @hotspotObj = ReadObjectFromID(hotspot.GetID());
    Object @lastPoint = ReadObjectFromID(points[points.size() - 1]);
    DebugDrawWireBox(hotspotObj.GetTranslation(), vec3(0.5f), vec3(1, 0, 0), _delete_on_update);
    DebugDrawWireBox(lastPoint.GetTranslation(), vec3(0.5f), vec3(0, 1, 0), _delete_on_update);
}

void AddPoint() {
    int objectID = CreateObject(placeholder);
    points.insertLast(objectID);
    Object @obj = ReadObjectFromID(objectID);
    obj.SetScale(vec3(0.5f));
    obj.SetCopyable(true);
    obj.SetDeletable(true);
    obj.SetSelectable(true);
    obj.SetTranslatable(true);
    obj.SetScalable(false);
    obj.SetRotatable(false);
    obj.SetTranslation(ReadObjectFromID(hotspot.GetID()).GetTranslation() + vec3(0, 1, 0));
    ScriptParams @placeholderParams = obj.GetScriptParams();
    placeholderParams.AddString("belongsto", "" + hotspot.GetID());
}
