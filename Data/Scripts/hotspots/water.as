//-----------------------------------------------------------------------------
//           Name: water.as
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

const int _ragdoll_state = 4;
const int headBone = 30;
const float underWaterInterval = 0.5f;
const float timeBeforeDrowning = 10.0f;

array<Victim@> victims;
float timeElapsed = 0.0f;
float updateInterval = 0.001f;
Object@ hotspotObj = ReadObjectFromID(hotspot.GetID());

void SetParameters() {
    params.AddFloatSlider("XVel", 0.0f, "min:-10.0,max:10.0,step:0.1,text_mult:10");
    params.AddFloatSlider("ZVel", 0.0f, "min:-10.0,max:10.0,step:0.1,text_mult:10");
}

void Reset() {
    for (uint i = 0; i < victims.length(); ++i) {
        victims[i].Reset();
    }
    victims.resize(0);
}

void HandleEvent(string event, MovementObject@ mo) {
    if (event == "enter") {
        OnEnter(mo);
    } else if (event == "exit") {
        OnExit(mo);
    }
}

void OnEnter(MovementObject@ mo) {
    if (FindVictimIndex(mo.GetID()) != -1) {
        return;
    }
    victims.insertLast(Victim(mo));
}

void OnExit(MovementObject@ mo) {
    int index = FindVictimIndex(mo.GetID());
    if (index == -1) {
        return;
    }
    victims[index].RestoreCharacterState();
    victims.removeAt(index);
}

void Update() {
    if (victims.length() == 0) {
        return;
    }

    timeElapsed += time_step;
    if (timeElapsed <= updateInterval) {
        return;
    }

    for (uint i = 0; i < victims.length(); ++i) {
        Victim@ victim = victims[i];
        if (victim.character.GetIntVar("state") != _ragdoll_state) {
            HandleCharacterInWater(victim);
        } else {
            HandleRagdollInWater(victim);
        }
    }
    timeElapsed = 0.0f;
}

void HandleCharacterInWater(Victim@ victim) {
    vec3 charPos = victim.character.position;
    float waterSurfaceY = hotspotObj.GetTranslation().y + (2.0f * hotspotObj.GetScale().y);
    vec3 hotspotTop = vec3(charPos.x, waterSurfaceY, charPos.z);
    vec3 ground = col.GetRayCollision(charPos, vec3(charPos.x, charPos.y - 2.0f, charPos.z));
    float waterDepth = distance(hotspotTop, ground);

    CheckHeadUnderWater(victim, hotspotTop);

    if (victim.character.GetBoolVar("on_ground")) {
        AdjustCharacterSpeed(victim, waterDepth);
    } else {
        ApplyWaterResistance(victim);
    }

    ToggleRollingAbility(victim, waterDepth);
}

void HandleRagdollInWater(Victim@ victim) {
    if (victim.character.GetBoolVar("frozen")) {
        return;
    }
    vec3 charPos = victim.character.position;
    float waterSurfaceY = hotspotObj.GetTranslation().y + (2.0f * hotspotObj.GetScale().y);
    vec3 hotspotTop = vec3(charPos.x, waterSurfaceY, charPos.z);

    Skeleton@ skeleton = victim.character.rigged_object().skeleton();
    for (int i = 0; i < skeleton.NumBones(); ++i) {
        if (!skeleton.HasPhysics(i)) {
            continue;
        }
        mat4 transform = skeleton.GetBoneTransform(i);
        if (transform.GetTranslationPart().y < hotspotTop.y) {
            ApplyBuoyancy(victim, i, charPos, hotspotTop);
        }
    }
    victim.character.rigged_object().SetRagdollDamping(0.99f);
}

void CheckHeadUnderWater(Victim@ victim, const vec3& in hotspotTop) {
    Skeleton@ skeleton = victim.character.rigged_object().skeleton();
    mat4 headTransform = skeleton.GetBoneTransform(headBone);
    if (headTransform.GetTranslationPart().y < hotspotTop.y) {
        victim.headUnderWater = true;
        victim.headUnderWaterTimer += time_step;
        if (victim.headUnderWaterTimer > timeBeforeDrowning) {
            victim.character.Execute("SetKnockedOut(_dead); Ragdoll(_RGDL_INJURED);");
            PlayUnderwaterSound(victim.character.position, 0.5f);
        }
    } else {
        victim.headUnderWater = false;
        victim.headUnderWaterTimer = 0.0f;
    }
}

void AdjustCharacterSpeed(Victim@ victim, float waterDepth) {
    float newSpeed = max(0.1f, 1.0f - waterDepth);
    victim.SetCharacterSpeed(newSpeed);
}

void ApplyWaterResistance(Victim@ victim) {
    float inWaterResistance = 2.0f;
    victim.character.velocity.x *= pow(0.97f, inWaterResistance);
    victim.character.velocity.z *= pow(0.97f, inWaterResistance);
    if (victim.character.velocity.y > 0.0f) {
        victim.character.velocity.y *= pow(0.97f, inWaterResistance);
    }
    if (length_squared(victim.character.velocity) > 80.0f && victim.character.position.y < hotspotObj.GetTranslation().y) {
        victim.character.Execute("GoLimp();");
    }
}

void ToggleRollingAbility(Victim@ victim, float waterDepth) {
    float rollThreshold = 0.5f;
    if (waterDepth < rollThreshold && !victim.allowRoll) {
        victim.character.Execute("allow_rolling = true;");
        victim.allowRoll = true;
    } else if (waterDepth > rollThreshold && victim.allowRoll) {
        victim.character.Execute("allow_rolling = false;");
        victim.allowRoll = false;
    }
}

void ApplyBuoyancy(Victim@ victim, int boneIndex, const vec3& in charPos, const vec3& in hotspotTop) {
    float velocityMagnitude = length(victim.character.velocity);
    if (velocityMagnitude > 80.0f && charPos.y < hotspotTop.y) {
        victim.character.Execute("GoLimp();");
    }
    vec3 localVelocity = hotspotObj.GetRotation() * vec3(params.GetFloat("XVel"), 0.0f, params.GetFloat("ZVel"));
    victim.character.rigged_object().ApplyForceToBone(
        vec3(localVelocity.x, min(100.0f, 100.0f * distance(charPos, hotspotTop)), localVelocity.z),
        boneIndex
    );
}

void PlayUnderwaterSound(const vec3& in position, float pitch) {
    int soundID = PlaySound("Data/Sounds/voice/animal2/voice_bunny_groan_3.wav", position);
    SetSoundPitch(soundID, pitch);
}

int FindVictimIndex(int charId) {
    for (uint i = 0; i < victims.length(); ++i) {
        if (victims[i].character.GetID() == charId) {
            return int(i);
        }
    }
    return -1;
}

class Victim {
    MovementObject@ character;
    float originalSpeed;
    bool headUnderWater = false;
    bool allowRoll = true;
    float headUnderWaterTimer = 0.0f;

    Victim(MovementObject@ charRef) {
        @character = charRef;
        originalSpeed = character.GetFloatVar("p_speed_mult");
    }

    void Reset() {
        character.rigged_object().ClearBoneConstraints();
        character.Execute("allow_rolling = true;");
    }

    void RestoreCharacterState() {
        SetCharacterSpeed(originalSpeed);
        character.Execute("allow_rolling = true;");
    }

    void SetCharacterSpeed(float speed) {
        character.Execute(
            "p_speed_mult = " + speed + "; " +
            "run_speed = _base_run_speed * p_speed_mult; " +
            "true_max_speed = _base_true_max_speed * p_speed_mult;"
        );
    }
}
