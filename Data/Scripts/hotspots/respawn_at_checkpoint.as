//-----------------------------------------------------------------------------
//           Name: respawn_at_checkpoint.as
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

void HandleEvent(string event, MovementObject@ mo) {
    if (event == "enter") {
        OnEnter(mo);
    }
}

void OnEnter(MovementObject@ mo) {
    int checkpointId = FindLatestCheckpoint();
    if (checkpointId == -1) {
        return;
    }
    RespawnAtCheckpoint(mo, checkpointId);
}

int FindLatestCheckpoint() {
    float latestTime = -1.0f;
    int bestCheckpointId = -1;
    array<int>@ hotspotIds = GetObjectIDsType(_hotspot_object);
    for (uint i = 0; i < hotspotIds.length(); ++i) {
        Object@ obj = ReadObjectFromID(hotspotIds[i]);
        ScriptParams@ objParams = obj.GetScriptParams();
        if (objParams.HasParam("LastEnteredTime")) {
            float currTime = objParams.GetFloat("LastEnteredTime");
            if (currTime > latestTime) {
                latestTime = currTime;
                bestCheckpointId = hotspotIds[i];
            }
        }
    }
    return bestCheckpointId;
}

void RespawnAtCheckpoint(MovementObject@ mo, int checkpointId) {
    Object@ checkpointObj = ReadObjectFromID(checkpointId);
    mo.position = checkpointObj.GetTranslation();
    mo.velocity = vec3(0.0f);
}
