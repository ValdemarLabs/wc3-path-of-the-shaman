# Story and Quest Design

- **Status:** Living narrative bible
- **Created:** 22 August 2026
- **Reframed:** 21 September 2026
- **Scope:** Main story, character arcs, act structure, upper-level dialogue flow, narrative consequences, and story-content status

> This is the narrative source of truth for *Path of the Shaman*. It explains what story the player experiences and why each major quest or event matters. Exact rawcodes, APIs, quest metadata, trigger dependencies, production order, and World Editor checks belong in the [Story and Quest Implementation Ledger](Story%20and%20Quest%20Implementation%20Ledger.md).

## Table of contents

- [1. How to use this document](#1-how-to-use-this-document)
- [2. Story in one page](#2-story-in-one-page)
- [3. Narrative foundations](#3-narrative-foundations)
- [4. Principal character arcs](#4-principal-character-arcs)
- [5. Act I — The outcast and the Horde's call](#5-act-i--the-outcast-and-the-hordes-call)
- [6. Act II — The wolf and the wound](#6-act-ii--the-wolf-and-the-wound)
- [7. Act III — Roads, islands, and uneasy allies](#7-act-iii--roads-islands-and-uneasy-allies)
- [8. Act IV — Rifts of Elarindor](#8-act-iv--rifts-of-elarindor)
- [9. Act V — Fire, blood, and balance](#9-act-v--fire-blood-and-balance)
- [10. Companion, class, and side-story arcs](#10-companion-class-and-side-story-arcs)
- [11. Story consequence map](#11-story-consequence-map)
- [12. Open story decisions](#12-open-story-decisions)
- [13. Narrative writing rules](#13-narrative-writing-rules)
- [14. Related documents and maintenance](#14-related-documents-and-maintenance)

## 1. How to use this document

Read this file before writing or materially changing a main quest, character quest, story dialogue, dungeon narrative, or story-driven world event. Read only the relevant act and character sections when making a focused change, but check the consequence map and open decisions before establishing new canon.

### Two kinds of status

Narrative certainty and implementation state are different. Every major section uses both where useful.

| Marking | Meaning |
|---|---|
| **Canon** | Current story truth. Change only through an explicit design decision. |
| **Working canon** | Preferred direction, but unresolved details may still change. |
| **Open** | A question or branch that must not be silently treated as settled. |
| **Implemented** | Current JASS or confirmed World Editor behavior supports the beat. Runtime validation may still be pending. |
| **Partial** | Some required quest, dialogue, encounter, or consequence exists. |
| **Planned** | Narrative intent exists, but the complete playable beat does not. |
| **Verify in WE** | Current map data or an unexported GUI trigger must be inspected. |

Implementation details and the exhaustive quest-by-quest status live in the implementation ledger. Status here is deliberately upper-level: it answers whether the player can experience the described story movement.

### Document boundary

This file owns:

- the premise, themes, acts, reveals, and character development;
- the intended order and meaning of major story events;
- upper-level dialogue flow and the emotional state entering and leaving a scene;
- which decisions must echo later;
- the distinction between canon, working canon, and open questions.

The implementation ledger owns:

- QuestData identities, rawcodes, regions, items, APIs, and event contracts;
- exact prerequisites, rewards, objective counts, cleanup, and retry behavior;
- detailed content inventories and generic quest banks;
- World Editor recovery and validation work;
- source-file and voice-production passes.

## 2. Story in one page

### Core premise

**Canon**

Nazgrek is an outcast shaman who refused the corruption that consumed his people. He has built a life outside the Horde with Shadowclaw, believing distance and self-reliance can preserve what remains of his principles. When Sereneglade's animals and spirits begin behaving unnaturally, his attempt to protect a quiet sanctuary draws him toward a wider regional collapse—and back toward the people who once rejected him.

The Horde now needs the kind of shamanism it abandoned. Nazgrek must cooperate without surrendering his judgement, learn that isolation also has consequences, and decide whether belonging can exist without obedience.

### Player-facing story promise

The player should experience an open-world Warcraft RPG in which local troubles gradually form a recognizable pattern. Early events present symptoms: displaced beasts, damaged trees, restless dead, coercive rituals, unstable elements, and wounded magical land. Midgame stories separate true causes from opportunists and ordinary faction conflict. Late-game stories reveal an organized culture of binding and extraction without reducing every enemy to one hidden controller.

The final journey asks:

> What kind of shaman will Nazgrek choose to become when listening is slower than domination, cooperation risks betrayal, and power offers easier answers?

### Developer-known mystery answer

**Working canon**

The spiritual balance is failing because several powers exploit already-wounded land, spirits, beasts, death, and elemental forces at the same time. Satyr coercion, necromancy, fel and Dark Horde extraction, and unstable magical rifts reinforce one another. A void presence exploits the fractures rather than secretly controlling every faction.

The final central antagonist remains open. Their dramatic role is settled: they are Nazgrek's dark mirror, embodying binding, extraction, and command in opposition to communion, restraint, and reciprocal power.

### Five-act movement

| Act | Story movement | Central question | Current state |
|---|---|---|---|
| **I — The outcast and the Horde's call** | A local wildlife mystery forces Nazgrek into action; Zul'kis loses his landing party; both are drawn to Thork's Horde. | Can Nazgrek help the Horde without becoming its servant? | **Partial** |
| **II — The wolf and the wound** | The regional disturbance becomes personal through Shadowclaw and Ghostwalk Ridge. | Can self-reliance protect anyone from an organized threat? | **Planned; legacy evidence** |
| **III — Roads, islands, and uneasy allies** | Undeath, fel activity, refugees, engineers, and island factions reveal different forms of exploitation. | Which conflicts share a cause, and which merely exploit the same wounds? | **Partial** |
| **IV — Rifts of Elarindor** | Magical collapse converges around Aradion, Valeria, Kaelthir, and the rifts. | Can damaged people and places be restored without controlling them? | **Partial** |
| **V — Fire, blood, and balance** | Dragon, Dark Horde, elemental, and forge conflicts become the final test of Nazgrek's path. | What does a shaman owe to spirits, people, and power? | **Partial opening; finale planned** |

## 3. Narrative foundations

### The central dramatic irony

**Canon**

Nazgrek remained loyal to shamanism when his people abandoned it. The people who exiled him now need that loyalty to survive. This irony should remain alive throughout the Horde story; one meeting with Thork must not resolve it.

### The thematic argument

The strongest thematic question is:

> Does a shaman command power, or serve something greater than himself?

Traditional shamanism represents listening, reciprocity, restraint, balance, and responsibility. Fel, necromancy, coercive satyr magic, reckless magical extraction, and dark shamanism represent domination, sacrifice, control, and power without reciprocity.

Different characters test the theme from different angles:

| Character or force | Position in the argument |
|---|---|
| Nazgrek | Principles matter, but isolation can become avoidance. |
| Zul'kis | Protecting a community may demand compromise, but compromise can be manipulated. |
| Thork | Survival can justify hard choices, but necessity does not erase debt or guilt. |
| Garthork | The Horde may learn restraint, though old habits of treating nature as a tool remain. |
| Jin'Zun | Truth can arrive through strange observers whom authority dismisses. |
| Velyssara | Power that removes another person's choice is corruption in its clearest form. |
| Central antagonist | Spirits, demons, and people are resources to be bound by whoever has the will. |

### How the mystery escalates

The player should not be told the answer before they have seen the pattern.

1. Beasts act outside ordinary hunger and territory.
2. The apparent source is revealed as another victim.
3. Trees, spirits, and wildlife display related but not identical wounds.
4. Rituals and extraction traces prove that some disturbances are intentional.
5. Restless dead and corrupted places show that the damage crosses natural and spiritual boundaries.
6. Separate factions exploit the instability for different reasons.
7. Evidence reveals organized methods and a thematic enemy, not one mastermind behind every local dispute.

Recurring clues should include spiritual silence or contradiction, altered life, faction-specific binding or extraction marks, incomplete first explanations, and visible aftermath. Each faction's evidence must remain distinct; there is no universal villain symbol stamped on every problem.

### Worldbuilding boundary

Not every problem belongs to the main plot. Territorial disputes, hunger, revenge, politics, ambition, religious disagreement, banditry, and old grudges remain valid causes. The player should sometimes ask “is this connected?” and discover that the answer is yes, indirectly, or no.

## 4. Principal character arcs

### Nazgrek — belonging without obedience

**Canon foundation; working-canon destination**

Nazgrek begins isolated, principled, bitter, spiritually capable, and convinced that exile is safer than dependence. His starting belief is:

> I survived because I needed no one.

The story challenges that belief without proving his distrust foolish. He learns that isolation cannot protect Sereneglade, that the Horde contains people with different values, that refusing responsibility can harm others, and that cooperation need not mean surrender.

His ending should not be uncomplicated Horde loyalty. Nazgrek chooses what being a shaman means for himself: he protects people rather than institutions, works with allies without yielding moral judgement, and becomes capable of connection without repeating the submission he once refused.

Voice boundary: Nazgrek may be bitter, dry, proud, and forceful. He does not delight in dominating spirits, eagerly celebrate slaughter, or immediately swear renewed obedience to the Horde.

### Zul'kis — continuity after loss

**Canon foundation; planned continuation**

Zul'kis begins with family, a landing party, and hope that Thork's alliance can offer safety. Within his prologue, that security is destroyed and his elder brother is captured. He joins Nazgrek because survival, family, and answers require movement—not because his own story has ended.

His core motivation is safety and continuity for his surviving people. His fear is losing another family or home. His flaw is that practical compromise can become over-accommodation. Where Nazgrek may say some principles are worth exile, Zul'kis may answer that principles do not help the dead.

His long arc must preserve responsibility toward Zul'karak and the Darkspear survivors, doubts about Thork, personal shamanic growth, humor, warmth, and independent judgement.

### Chieftain Thork — survival and moral debt

**Canon characterization; hidden crime canon; consequences open**

Thork is not a penitent mentor and not a simple villain. He believes survival can require coercive choices and fears losing control of a fragile Horde. He needs Nazgrek's abilities and respects him more than he admits, but he also embodies the institution that cast Nazgrek out.

Thork secretly hired forest trolls to destroy the Darkspear landing and frame humans, intending to bind a grieving Zul'kis to the Horde through a manufactured enemy. Zul'karak's survival and the wounded witch doctor's testimony were unintended loose ends. The prologue must not reveal this truth; later evidence should make it discoverable.

The timing, confrontation, and consequences of the revelation remain open.

### Shadowclaw — sanctuary made personal

**Canon bond; fate open**

Shadowclaw is not merely an animal companion. The wolf represents Nazgrek's chosen life outside the Horde, his capacity for loyalty, and the sanctuary he believes he can defend alone. Early scenes should show mutual trust and Nazgrek's restraint when Shadowclaw reacts to danger.

Legacy material points toward Shadowclaw's permanent death during the Ghostwalk campaign. The exact version—direct murder, failed cleansing, or player-influenced outcome—must be decided before it becomes current canon. Whatever the result, it must alter Nazgrek, the companion systems, later dialogue, and the meaning of Ghost Wolf or ancestral progression.

### Jin'Zun — the dismissed witness

**Implemented foundation; planned story integration**

Jin'Zun's escalation from corrupted trees to unnatural entities and restless dead is one of the story's strongest existing structures. His humor and unusual cadence remain, but his milestone observations should be correct often enough that the player learns to take him seriously. He links the early wildlife mystery to Deadwoods, the Crypt, and the wider spiritual crisis.

### Garthork and Granis — the Horde is not one thing

**Implemented foundation; dialogue refinement planned**

Granis represents military necessity, vengeance, territorial thinking, and direct strength. Garthork represents investigation, shamanic knowledge, and the possibility that some within the Horde have learned restraint. Neither should be a caricature. Their contrast allows Nazgrek to test the assumption that the Horde is one unchanged institution.

## 5. Act I — The outcast and the Horde's call

**Narrative status:** Canon structure

**Implementation status:** Partial; Nazgrek's first hunt and Flask, Protect the Outpost, Zul'kis's prologue, convergence, and Horde proof quests have substantial implementation. Wolf Mother, Act I judgement, and several consequence beats remain planned.

### Act purpose

Act I begins with a personal sanctuary, introduces the first symptom of the larger disturbance, gives Zul'kis an independent loss and motive, and forces Nazgrek to engage with the Horde on conditional terms. It ends when Nazgrek has learned that the Horde contains real differences but has not yet decided it deserves trust.

### I-A — Nazgrek: the outcast and the wolf

#### Opening state

Nazgrek and Shadowclaw live at the edge of Sereneglade. The intro establishes exile, mutual loyalty, and Nazgrek's restraint without recounting his complete history. Player control should begin in a quiet space before the world's disturbance intrudes.

#### Story flow

1. **The strange attack — Planned.** Two wolves attack Nazgrek outside normal hunting behavior. This is the inciting event, not a journal instruction appearing without cause.
2. **Wolf Hunt I — Implemented; narrative refinement planned.** Nazgrek investigates unusual aggression while gathering hides. The objective teaches hunting and gathering, but the dramatic question is why the wolves are ranging and attacking this way.
3. **Nazgrek's Flask — Implemented; narrative refinement planned.** Nazgrek prepares an inherited shamanic aid for spiritual clarity or protection. Gathering ingredients introduces his practice and the forest ecosystem. The flask helps investigation; it is not a generic victory potion.
4. **Wolf Mother — Planned.** Nazgrek enters the den believing the Wolf Mother drives the aggression. During or after the confrontation, he discovers that she is affected by the same disturbance. The apparent cause becomes the first confirmed victim.
5. **Shamanic remembrance — Planned and optional.** A crafted cowl can turn the remains into respectful remembrance rather than a trophy. This beat must not delay the main story.
6. **Protect the Outpost — Implemented.** Nazgrek helps people under attack despite insisting that he owes the Horde nothing. Ragno recognizes service motivated by principle rather than obedience.

#### Upper-level dialogue flow

- **Intro:** narrator or Nazgrek gives only enough history to establish exile; patrol pressure lets behavior show his restraint; the scene ends in present-tense sanctuary rather than exposition.
- **Wolf attack:** Nazgrek observes that the attack is wrong; he does not already know its supernatural cause.
- **Flask preparation:** Nazgrek connects the recipe to inherited practice and uncertainty; ingredient reminders remain practical.
- **Wolf Mother aftermath:** attempted understanding precedes judgement; Nazgrek concludes that Sereneglade itself is threatened.
- **Outpost aftermath:** Ragno frames the act as evidence that Nazgrek still cares; Nazgrek distinguishes helping lives from serving the Horde.

#### Exit state

Nazgrek has evidence that the forest's disorder is wider than one predator. He has acted for others despite his isolation and receives a blood-signed summons from Thork, but the story pauses his decision while the player experiences Zul'kis's parallel beginning.

### I-B — Zul'kis: the broken landing

#### Opening state

Zul'kis arrives with a living Darkspear shore party and his elder brother Zul'karak. He expects a short meeting with Thork and a workable alliance. Zul'karak relays the wise one's warning of a dark threat, establishing unease without identifying its source.

#### Story flow

1. **Arrival and brothers on the shore — Implemented.** Establish kinship, the tribe's hope, and Zul'kis's willingness to trust the alliance.
2. **Meeting Thork — Implemented.** Thork's concern about the missing tribe sends Zul'kis back toward the shore.
3. **The broken landing — Implemented.** Zul'kis finds the party destroyed, receives incomplete testimony from a dying survivor, and encounters an apparently helpful orc patrol.
4. **Rescue the Brother — Implemented.** Zul'kis and the patrol fight through Bramblehide Village and recover Zul'karak, whose captors questioned what he witnessed.
5. **Return to the Horde — Implemented.** Zul'kis chooses proximity to safety and answers, while gaps in the official account remain available for a later investigation.

#### Upper-level dialogue flow

- **Shore departure:** Zul'karak voices caution; Zul'kis answers with practical confidence in Thork's promise.
- **Return:** shock becomes a focused search for family rather than immediate exposition.
- **Survivor:** testimony identifies violence and uncertainty, then ends before naming the perpetrators.
- **Patrol:** the orcs present themselves as chance allies and guide the interpretation toward humans without proving it.
- **Rescue:** the brothers confirm exterminatory intent and suspicious questioning, but cannot yet identify who arranged the attack.

#### Hidden truth and fair clues

Thork's false flag is canon, but the player must have a fair later path to infer it. Reusable evidence may include inconsistent weapon marks, impossible timing, missing rather than destroyed supplies, forest-troll payment, patrol contradictions, or survivor testimony. No single clue should solve the mystery during the prologue.

#### Exit state

Zul'kis has saved his brother but lost the certainty of home. He remains near the Horde for survival and answers. His grief and suspicion must continue after recruitment.

### I-C — Convergence and earning a place

#### Story flow

1. **Call of the Horde — Implemented.** Nazgrek carries Ragno's summons to Thork and meets Zul'kis. The meeting creates a practical alliance, not instant friendship or reconciliation.
2. **Duty For The Horde — Implemented spine.** Thork demands proof through Granis and Garthork. Nazgrek observes different faces of the Horde while Zul'kis sees a possible route to security.
3. **Military proof — Implemented.** Granis tests force, loyalty, and the practical cost of defending territory.
4. **Spiritual proof — Implemented; framing refinement planned.** Garthork tests investigation and shamanic knowledge, showing incomplete but meaningful change within the Horde.
5. **Gnoll and satyr truth — Partial.** Stolen resources, external organization, and Zaekolaerr's offer complicate the local conflict. Choices should create later consequences rather than parallel campaigns.
6. **Thork's judgement — Planned.** Thork grants conditional standing. Nazgrek accepts a route forward while explicitly withholding unconditional loyalty.

#### Upper-level dialogue flow

- **First meeting:** Thork needs Nazgrek but resists admitting the full debt; Nazgrek refuses easy reconciliation; Zul'kis argues for practical cooperation without becoming a passive mediator.
- **Granis:** the conversation tests whether necessary violence becomes enthusiasm or remains a burden.
- **Garthork:** shared history establishes credibility; investigation shows whether the Horde can seek understanding rather than merely useful power.
- **Judgement:** each side names terms. Cooperation becomes possible, trust remains earned, and the next crisis gives the alliance a direction.

#### Act I exit state

Nazgrek and Zul'kis travel together. Nazgrek has conditional access to the Horde but retains independence. The first mystery has expanded from animals to deliberate interference, and Ghostwalk Ridge offers the next trail.

## 6. Act II — The wolf and the wound

**Narrative status:** Working canon; Shadowclaw outcome open

**Implementation status:** Planned from legacy evidence and current zone/character support

### Act purpose

Act II makes the spiritual disturbance personally costly. Nazgrek enters believing that vigilance and personal strength can protect the small life he built. Ghostwalk Ridge and Deadwoods reveal a more organized use of fel and spiritual domination than the early Sereneglade symptoms suggested.

### Main movement

1. **Road to Ghostwalk — Planned.** Reports from Ironspine, Erduk's murloc pressure, and Jin'Zun's evidence point toward displaced threats and corrupted ground.
2. **Shadowclaw under pressure — Planned.** The bond that represented sanctuary becomes vulnerable to the same forces affecting beasts and spirits.
3. **The wound — Open variant.** Shadowclaw dies, is lost through a failed cleansing, or reaches a player-influenced outcome. The version must preserve consequence and avoid using loss as a disposable motivation.
4. **Blood trail and fel evidence — Planned.** Nazgrek follows evidence from personal harm to an organized warband or operation.
5. **Deadwoods opening — Planned.** The investigation reveals that undeath and spiritual binding overlap with, but are not identical to, fel corruption.

### Upper-level dialogue flow

- Nazgrek initially treats warnings as something he can solve alone.
- Zul'kis challenges the difference between protecting someone and refusing help.
- Garthork or Jin'Zun helps distinguish symptoms from a deliberate method.
- The central loss or transformation leaves room for grief, anger, and uncertainty before the next objective.
- Act-end dialogue turns vengeance into investigation: the party will follow who benefits and how the binding was done, not merely kill the nearest faction.

### Act exit state

Nazgrek can no longer pretend the crisis is external to his chosen life. The party has evidence of organized exploitation and a path into Deadwoods, Dawnhold, and the Crypt.

## 7. Act III — Roads, islands, and uneasy allies

**Narrative status:** Working-canon structure

**Implementation status:** Partial; several regional quests, the Boom Brothers chain, Gar encounter support, ambient conflicts, and travel systems exist

### Act purpose

Act III widens the world without dissolving the main story. The party meets conflicts caused by the central disturbance, conflicts exploiting it, and conflicts with independent roots. Nazgrek must build alliances while refusing the idea that one faction label explains every person's motives.

### III-A — Ironspine, Deadwoods, and the Crypt

Jin'Zun's observations, restless dead, Gar, and Dawnhold's curse turn early clues into material evidence. The Crypt should have a breadcrumb, a story conclusion, and optional repeatable tasks, but only its one-time evidence advances the main plot.

Dialogue movement: witnesses describe effects before scholars name causes; Garthork and Jin'Zun compare interpretations; bound spirits expose the moral cost of treating the dead as resources; the party leaves with evidence another region can recognize.

### III-B — Dawnhold and Stormhaven

Dawnhold is the ruined city and docks inherited from older “Vanguard” notes; it must not be confused with Vanguard Vale. Refugees and survivors make the crisis human rather than purely magical. Ship work should deepen access, service, or a story route rather than pretend that existing travel never existed.

Dialogue movement: survivors provide contradictory accounts; the party earns trust through aid; necromantic and fel evidence are distinguished; the repaired or secured route makes the next journey a consequence of helping people.

### III-C — Sirensong and the Boom Mine

The Boom Brothers chain offers comic energy without becoming narratively disposable. Atex Blix's betrayal and Mad Blix's mine show greed, unsafe extraction, and technological domination as a smaller reflection of the main theme. Mok'natha, island factions, ruins, naga, and hydra threats create a regional struggle in which not every battle serves the central antagonist.

Dialogue movement: humor establishes the engineers' voice; escalating hazards reveal exploitation beneath the comedy; betrayal changes who owns the mine; later access or material support makes the outcome visible.

### Act exit state

The party has allies, travel routes, and evidence that multiple groups are using the same wounded world in different ways. The magical rifts of Elarindor become the clearest place where those pressures converge.

## 8. Act IV — Rifts of Elarindor

**Narrative status:** Working canon

**Implementation status:** Partial; Aradion and Valeria's central quest sequence and Kaelthir's side chain are implemented, while regional consequences remain planned

### Act purpose

Act IV asks whether damaged land and people can be restored without reducing them to problems to control. Aradion and Valeria become partners with their own stakes, while Kaelthir gives the magical collapse a personal face.

### Main movement

1. **Ranger Missing — Implemented.** Finding Valeria establishes the player's approach through rescue, combat, or negotiation.
2. **Elarindor made personal — Implemented side material.** Valeria's smaller quests reveal attachments and ordinary life worth preserving.
3. **Crystals of Hope — Implemented.** The party gathers what is needed to stabilize Elarindor, but the story must frame the crystals as a means of repair rather than another resource grab.
4. **Fading Sparks — Implemented.** Wraiths connect earlier Deadwoods and void clues to the current magical crisis.
5. **Kaelthir's struggle — Implemented branching side chain.** Mercy, transformation, or failed cure demonstrates what magical hunger does to an individual. The outcome must be acknowledged later.
6. **Rifts of Corruption — Implemented.** Three rituals form the act's convergence and expose the route or source leading toward the endgame.
7. **Verdant consequence — Planned.** Satyr choices, ritual success, and Kaelthir's fate alter assistance, enemies, or dialogue in Weeping Hollow and Vael'Anorath.

### Upper-level dialogue flow

- Aradion speaks from duty to a threatened people, not merely as a quest distributor.
- Valeria challenges easy assumptions about Elarindor and gives the party a personal relationship to the region.
- Kaelthir's scenes keep the cost of magical collapse embodied and morally uncomfortable.
- Ritual dialogue emphasizes listening, stabilization, and sacrifice without making Nazgrek the sole expert in another culture's crisis.
- The act-end revelation should identify the endgame route and method while preserving remaining antagonist uncertainty until the chosen reveal point.

### Act exit state

The party understands that rifts, elemental exploitation, fel industry, and spiritual damage can reinforce one another. Prior choices determine who offers support and what has survived, but the finale remains reachable.

## 9. Act V — Fire, blood, and balance

**Narrative status:** Working-canon direction; central antagonist and final sequence open

**Implementation status:** Grum's Emberpeak chain is implemented; Dragonfire fronts, endgame dungeons, and finale are planned

### Act purpose

Act V merges the external crisis with Nazgrek's internal question. Dragons, elementals, Dark Horde forces, and forge operations show power treated as fuel. Nazgrek must oppose that system without becoming its mirror.

### V-A — Emberpeak warning

Grum Bloodfang's hunts provide an existing opening: dangerous whelps, recovered eggs, drakes, and Mordrax. The unresolved meaning of the eggs is crucial. Grum may protect, weaponize, betray, or misunderstand; that answer determines whether the chain foreshadows stewardship or exploitation.

### V-B — Dragonfire fronts

Ashfang, Morgrim's Claim, Wyrmfall, the Maw of Cinders, and Scorchion reveal competing operations rather than one uniform army. Earlier treatment of dragons, elementals, satyrs, and faction allies should alter support and encounter conditions.

### V-C — Wyrmhold, Firelands, and Dreadforge

The endgame dungeons should each answer a different part of the crisis:

- **Wyrmhold Sanctum:** the fate and agency of dragons, including Dragon Mother Seretha and the earlier eggs;
- **Firelands:** the damaged elemental covenant and the difference between alliance and enslavement;
- **Dreadforge:** the industrial system turning fel, spirits, bodies, and elemental power into tools of war.

The order may change tactical support, but no optional daily or repeatable grind may gate the finale.

### V-D — Path of the Shaman

Nazgrek rejects borrowed corruption and the antagonist's promise of command. Victory requires restored relationships and covenants, not only greater destructive power. Allies and epilogue states reflect prior choices, while Nazgrek defines a path that is neither blind Horde obedience nor lonely withdrawal.

### Upper-level finale dialogue flow

- The antagonist articulates a coherent belief: service is weakness; power should be bound by those capable of taking it.
- Nazgrek recognizes the appeal because domination appears efficient and because his own pride has often rejected reciprocal dependence.
- Zul'kis, Thork, companions, and regional allies reflect different costs of compromise and control.
- Nazgrek's answer is demonstrated through action—freeing, restoring, sharing risk, or accepting aid—before it is summarized in words.
- The epilogue records relationships and consequences rather than declaring every wound healed.

### Final state

Nazgrek has connection without submission, responsibility without institutional obedience, and strength without domination. The world is repaired enough to continue, not reset to innocence.

## 10. Companion, class, and side-story arcs

### Shaman progression as character progression

**Elemental chain implemented mechanically; narrative integration planned**

| Covenant | Character lesson | Story echo |
|---|---|---|
| Air | Freedom joined to responsiveness | Nazgrek's independence cannot become detachment. |
| Earth | Endurance joined to responsibility | Surviving alone is not the same as standing for a place or people. |
| Fire | Power governed by restraint | The endgame shows what fire becomes when treated only as fuel. |
| Water | Change, healing, and restoration | Victory must repair as well as destroy. |
| Ghost Wolf / ancestors / totems | Memory, relationship, and legacy | Shadowclaw, Deadwoods, and the meaning of what Nazgrek carries forward. |

Each covenant needs a concise premise and completion reflection. It should change how the player reads Nazgrek's journey without turning class progression into disconnected trainer errands.

### Velyssara and Chains of Seduction

**Implemented foundation; allegiance and fate open**

Velyssara's removal of Nazgrek's agency makes this story thematically important. It literalizes the principle that power which removes choice is corruption. Her relationship to Zaekolaerr and the possibility of cleansing, sparing, or only defeating her remain open.

### Satyr negotiations

**Partial**

Zaekolaerr's arena, hostile, and apparent-cooperation routes should converge geographically while changing later trust, aid, enemy composition, and dialogue. Dark choices may carry costs, but the story must not strand the player without a viable campaign route.

### Zul'karak after rescue

**Planned**

Zul'karak needs a short non-gating quest set and later recruit possibility. More importantly, he is a living witness and emotional anchor for Zul'kis. His doubts, memory, and response to the false-flag evidence must matter even if he never becomes an active companion.

### Generic and regional quests

Side content should have one clear primary function: character, faction, worldbuilding, mystery, class, comedy, or exploration. Daily and repeatable quests provide local texture and reputation; they do not define mandatory canon or gate the main story. The implementation ledger owns the full regional quest bank.

## 11. Story consequence map

| Earlier event or choice | Required later echo | Status |
|---|---|---|
| Wolf Mother revealed as victim | Jin'Zun, Garthork, or later evidence recognizes the same family of disturbance | **Planned** |
| Nazgrek defends Ragno's outpost | Horde dialogue acknowledges service by principle rather than obedience | **Planned refinement** |
| Zul'kis's landing is destroyed | Grief, Zul'karak's account, and contradictions remain active after recruitment | **Partial** |
| Granis and Garthork proof quests | Thork's judgement reflects two different faces of the Horde | **Planned** |
| Satyr Negotiations outcome | Verdant allies, enemies, trust, and dialogue change | **Partial / planned consequence** |
| Jin'Zun's escalating evidence | Deadwoods, Crypt, Garthork, and Dawnhold recognize accumulated clues | **Planned integration** |
| Shadowclaw outcome | Companion behavior, Nazgrek dialogue, and later spirit/class content change | **Open** |
| Boom Mine reclaimed | Ownership, access, service, or renewable benefit visibly changes | **Partial** |
| Kaelthir's fate | Later Elarindor dialogue and assistance acknowledge the chosen outcome | **Planned consequence** |
| Grum receives dragon eggs | Wyrmhold or Dragonfire reveals what he did and changes dragon relations | **Open** |
| Elemental covenants | Dark-shaman and finale scenes recognize how Nazgrek learned reciprocal power | **Planned** |
| Thork's false flag exposed | Zul'kis, Zul'karak, Nazgrek, and Horde standing/support react | **Open consequence** |

Consequences need not create separate campaigns. A changed greeting, absent or present supporter, altered patrol, encounter assistance, accessible service, environmental change, or short companion exchange can make a decision visible.

## 12. Open story decisions

These questions are intentionally unresolved. Do not establish an answer incidentally in quest text.

1. Who is the central dark-mirror antagonist, what do they directly control, and why does Nazgrek matter to them?
2. What exact event first caused or exposed the regional spiritual fractures?
3. What is Shadowclaw's canonical fate, and what replaces every narrative and gameplay dependency afterward?
4. When and how is Thork's false flag discovered, and what changes after the confrontation?
5. How far may Zaekolaerr's darker route go while preserving character logic and a viable hub?
6. Is Velyssara Zaekolaerr's agent, rival, coerced ally, or an independent corrupter, and what outcomes are possible?
7. What does Grum intend to do with the recovered dragon eggs, and how does that choice affect Wyrmhold?
8. Who ruled old Dawnhold, and what does the Crypt's crown choice mean in current canon?
9. What is Gar's story ownership and canonical outcome in Deadwoods?
10. What is the final name, faction, and narrative role of Verdant settlement `1704`?

## 13. Narrative writing rules

### The before / revelation / after test

For every major quest or scene, write three sentences before writing detailed dialogue:

1. **Before:** What does Nazgrek, Zul'kis, or the player believe?
2. **Revelation:** What do they discover or reinterpret?
3. **After:** What changes in action, relationship, knowledge, or the world?

If the answer to “after” is only “the reward is granted,” the content is not yet carrying enough story weight.

### Dialogue-flow rule

Before drafting lines, record:

- why the scene begins now;
- what each speaker wants from it;
- what information or emotion turns the scene;
- what remains unsaid or misunderstood;
- what playable state or next decision ends the scene.

Upper-level flow belongs here. Final line text and audio ownership belong with the quest and voice-production work.

### Character and world rules

- Preserve Nazgrek's principles without making him infallible.
- Preserve Zul'kis's own family, community, and judgement after recruitment.
- Keep Thork morally complicated; neither absolve nor flatten him.
- Let Jin'Zun be funny without making his observations meaningless.
- Give factions rational motives and internal differences.
- Connect through causality and consequence, not a universal hidden mastermind.
- Prefer one earlier clue and one later callback over adding another exposition quest.
- Do not make daily or repeatable content mandatory for the main story.
- Keep branch scope buildable: vary support, state, and dialogue more often than geography.

## 14. Related documents and maintenance

### Document map

| Document | Role |
|---|---|
| **This file** | Narrative bible: acts, character arcs, story truth, dialogue flow, consequences, and open story decisions |
| [Story and Quest Implementation Ledger](Story%20and%20Quest%20Implementation%20Ledger.md) | Technical and production source of truth: quest inventory, statuses, dependencies, rawcodes, event contracts, regional quest bank, and WE follow-up |
| [PotS Story Design Guide](PotS_Story_Design_Guide.md) | Dated repository-review analysis that produced the main narrative recommendations; retained as provenance, not a competing source of truth |
| `Zones/ZonesCore.j` | Current zone identity, hierarchy, level, and boss baseline |
| Current JASS and World Editor data | Authority for implemented behavior; reconcile discoveries with both design documents |

### Provenance from the earlier guide

The substantive recommendations from `PotS_Story_Design_Guide.md` are incorporated here: preserve the current world, strengthen causality, center Nazgrek, keep Zul'kis's parallel introduction, turn Wolf Mother into the first victim/reveal, treat the Horde as a character conflict, use communion versus domination as the theme, structure the story into acts, apply the before/revelation/after test, preserve unrelated world conflicts, and make shaman progression part of character growth.

The guide remains useful for the original critique and reasoning. New story decisions should be recorded here; implementation changes belong in the ledger. Do not maintain three parallel versions of current canon.

### Maintenance rules

- Update this file when a quest changes story meaning, act placement, character outcome, revealed information, or later consequence.
- Update the implementation ledger when code, objects, triggers, dependencies, status, or validation requirements change.
- Update both when implementation establishes or contradicts narrative canon.
- Record rejected legacy ideas briefly rather than silently allowing them to reappear as current truth.
- Treat `_MISC/war3map.wts` and legacy notes as read-only evidence.
- Review act status and the consequence map after completing a major story or zone pass.
