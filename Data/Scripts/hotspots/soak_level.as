//-----------------------------------------------------------------------------
//           Name: soak_level.as
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

float elapsedTimeBeforeReload = 0.0f;
bool levelLoadTriggered = false;

void SetParameters() {
    params.AddString("NextLevel", "");
    params.AddFloat("TimeToNextLevel", 5.0f);
}

void Update() {
    string nextLevelPath = params.GetString("NextLevel");
    if (nextLevelPath == "") {
        return;
    }
    float timeToNextLevel = params.GetFloat("TimeToNextLevel");
    elapsedTimeBeforeReload += time_step;

    DebugText("soaktest1", "Time til next level: " + (timeToNextLevel - elapsedTimeBeforeReload), 0.5f);

    if (elapsedTimeBeforeReload >= timeToNextLevel && !levelLoadTriggered) {
        levelLoadTriggered = true;
        level.SendMessage("loadlevel \"" + nextLevelPath + "\"");
    }
}
