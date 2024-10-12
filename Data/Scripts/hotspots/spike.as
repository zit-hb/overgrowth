//-----------------------------------------------------------------------------
//           Name: spike.as
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

int spikeCount = 5;
int spikedCharacterId = -1;
int spikeTipHotspotId = -1;
int spikeCollidableId = -1;
int noGrabId = -1;
int armed = 0;
bool isShortSpike = false;
const bool superSpike = false;

void SetParameters() {
    isShortSpike = params.HasParam("Short");
}

void Init() {
    // Initialization if needed
}

void Reset() {
    spikeCount = 5;
    spikedCharacterId = -1;
    armed = 0;
    UpdateObjects();
}

void Dispose() {
    DeleteObjectIfExists(spikeCollidableId);
    DeleteObjectIfExists(spikeTipHotspotId);
    DeleteObjectIfExists(noGrabId);
}

void HandleEvent(string event, MovementObject@ mo) {
    if (event == "enter") {
        // OnEnter(mo); // No action needed on enter
    } else if (event == "exit") {
        // OnExit(mo); // No action needed on exit
    } else if (event == "reset") {
        spikeCount = 20;
    }
}

void ReceiveMessage(string msg) {
    if (superSpike) {
        return;
    }
    if (msg == "arm_spike") {
        SetArmed(1);
    } else if (msg == "disarm_spike" && spikedCharacterId == -1) {
        SetArmed(0);
    }
}

void Update() {
    if (armed != 1) {
        return;
    }
    CheckForSpikeCollision();
}

void PreDraw(float curr_game_time) {
    UpdateObjects();
}

void SetArmed(int value) {
    if (value == armed) {
        return;
    }
    armed = value;
    UpdateObjects();
}

void UpdateObjects() {
    CreateSpikeCollidable();
    CreateSpikeTipHotspot();
    CreateNoGrabHotspot();
    UpdateTransforms();
    UpdateCollisionState();
}

void CreateSpikeCollidable() {
    if (spikeCollidableId != -1) {
        return;
    }
    string spikePath = isShortSpike
        ? "Data/Objects/Environment/camp/sharp_stick_short.xml"
        : "Data/Objects/Environment/camp/sharp_stick_long.xml";
    spikeCollidableId = CreateObject(spikePath, true);
    ReadObjectFromID(spikeCollidableId).SetEnabled(true);
}

void CreateSpikeTipHotspot() {
    if (spikeTipHotspotId != -1) {
        return;
    }
    spikeTipHotspotId = CreateObject("Data/Objects/Hotspots/spike_tip.xml", true);
    Object@ obj = ReadObjectFromID(spikeTipHotspotId);
    obj.SetEnabled(true);
    obj.GetScriptParams().SetInt("Parent", hotspot.GetID());
}

void CreateNoGrabHotspot() {
    if (noGrabId != -1) {
        return;
    }
    noGrabId = CreateObject("Data/Objects/Hotspots/no_grab.xml", true);
}

void UpdateTransforms() {
    Object@ hotspotObj = ReadObjectFromID(hotspot.GetID());
    vec3 position = hotspotObj.GetTranslation();
    quaternion rotation = hotspotObj.GetRotation();
    vec3 scale = hotspotObj.GetScale();

    UpdateSpikeTipTransform(position, rotation, scale);
    UpdateSpikeCollidableTransform(position, rotation, scale);
    UpdateNoGrabTransform(position, rotation, scale);
}

void UpdateSpikeTipTransform(const vec3& in position, const quaternion& in rotation, const vec3& in scale) {
    if (spikeTipHotspotId == -1) {
        return;
    }
    Object@ obj = ReadObjectFromID(spikeTipHotspotId);
    obj.SetRotation(rotation);
    obj.SetTranslation(position + rotation * vec3(0, scale.y * 2 + 0.2f, 0));
    obj.SetScale(vec3(0.2f));
}

void UpdateSpikeCollidableTransform(const vec3& in position, const quaternion& in rotation, const vec3& in scale) {
    if (spikeCollidableId == -1 || armed == 1) {
        return;
    }
    Object@ obj = ReadObjectFromID(spikeCollidableId);
    float yScale = scale.y * 2.0f * (isShortSpike ? 0.92f : 0.85f);
    obj.SetRotation(rotation);
    obj.SetTranslation(position + rotation * vec3(0.03f, 0, 0.0f));
    obj.SetScale(vec3(1, yScale, 1));
}

void UpdateNoGrabTransform(const vec3& in position, const quaternion& in rotation, const vec3& in scale) {
    if (noGrabId == -1) {
        return;
    }
    Object@ obj = ReadObjectFromID(noGrabId);
    Object@ referenceObj = ReadObjectFromID(spikeCollidableId);
    obj.SetRotation(rotation);
    obj.SetTranslation(position);
    obj.SetScale(vec3(1, scale.y * 0.45f, 1) * referenceObj.GetBoundingBox());
}

void UpdateCollisionState() {
    if (spikeCollidableId == -1) {
        return;
    }
    ReadObjectFromID(spikeCollidableId).SetCollisionEnabled(armed == 0);
}

void CheckForSpikeCollision() {
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    vec3 start = obj.GetTranslation() - obj.GetRotation() * vec3(0, obj.GetScale().y * 2, 0);
    vec3 end = obj.GetTranslation() + obj.GetRotation() * vec3(0, obj.GetScale().y * 2, 0);
    vec3 direction = normalize(end - start);

    vec3 checkStart = superSpike ? start : end - direction * 0.1f;
    vec3 checkEnd = end + direction * 0.05f;

    col.CheckRayCollisionCharacters(checkStart, checkEnd);
    if (sphere_col.NumContacts() == 0) {
        return;
    }

    MovementObject@ character = ReadCharacterID(sphere_col.GetContact(0).id);
    if (!superSpike && dot(character.velocity, direction) >= 0.0f) {
        return;
    }

    if (spikeCount > 0) {
        character.rigged_object().Stab(
            sphere_col.GetContact(0).position,
            direction,
            (spikeCount == 4) ? 1 : 0,
            0
        );
        --spikeCount;
    }

    if (spikedCharacterId != -1) {
        return;
    }

    SpikeCharacter(character, start, end);
}

void SpikeCharacter(MovementObject@ character, const vec3& in start, const vec3& in end) {
    vec3 dir = normalize(start - end);
    float extend = 0.4f;

    CheckAndSpikeRagdoll(character, start + dir * extend, end - dir * extend, dir);
    CheckAndSpikeRagdoll(character, end - dir * extend, start + dir * extend, -dir);

    PlaySoundGroup("Data/Sounds/weapon_foley/cut/flesh_hit.xml", character.position);

    spikedCharacterId = character.GetID();
    if (character.GetIntVar("knocked_out") != _dead) {
        character.Execute(
            "TakeBloodDamage(1.0f);"
            "Ragdoll(_RGDL_INJURED);"
            "injured_ragdoll_time = RangedRandomFloat(0.0, 12.0);"
            "death_hint = _hint_avoid_spikes;"
        );
    }
}

void CheckAndSpikeRagdoll(MovementObject@ character, const vec3& in start, const vec3& in end, const vec3& in dir) {
    col.CheckRayCollisionCharacters(start, end);
    for (int i = 0; i < sphere_col.NumContacts(); ++i) {
        int bone = sphere_col.GetContact(i).tri;
        character.rigged_object().SpikeRagdollPart(bone, start, end, sphere_col.GetContact(i).position);
    }
}

void DeleteObjectIfExists(int& inout objectId) {
    if (objectId != -1) {
        QueueDeleteObjectID(objectId);
        objectId = -1;
    }
}
