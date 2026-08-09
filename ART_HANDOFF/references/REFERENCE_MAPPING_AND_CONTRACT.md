# Reference Mapping + Runtime Contract

- Grave Guard -> grave_guard_concept_sheet.png
- Lantern Tosser -> lantern_tosser_concept_sheet.png
- Hook Brute -> hook_brute_concept_sheet.png
- Bell Keeper -> bell_keeper_concept_sheet.png
- Bilge Crawler -> bilge_crawler_concept_sheet.png (**directional only; final must be more humanoid corpse, less literal spider**)
- Hanged Sailor -> hanged_sailor_concept_sheet.png
- Bone Crow -> bone_crow_concept_sheet.png
- Coffin Mimic -> coffin_mimic_concept_sheet.png

Actual runtime contract (updated post-0.11.3): 10 separate 96x80 PNGs per enemy named
enemy_0.png through enemy_9.png. Frame order is dead, hurt/rise, idle A, idle B,
movement A, movement B, attack windup, attack release, movement C, movement D.

Frames 4, 5, 8, 9 together form ONE 4-pose movement cycle played back in the order
4 -> 5 -> 8 -> 9 -> loop (a 2-frame walk cycle read as a "shuffle" in playtesting).
Frames 6/7 sit between them only in file-index order. 8/9 must mirror/continue the
stride or wingbeat established in 4/5, not relate to the attack pose.
