# WC3 - Path of the Shaman
## FAQ
Last updated: 2026-08-07
> ### FAQ usage notes:
> This document contains frequently asked questions about `WC3 - Path of the Shaman` and its development.

<details>
<summary><strong>FAQ: Are you doing the work alone or do you have a team of people working on this?</strong></summary>
At the moment I work alone, but if there are people interested in joining the project, I'm more than happy to discuss.
Creating a huge RPG map alone is a lot of work, so progress can sometimes be slow.

><strong>The most useful help would currently be for:</strong><
- Overall gameplay testing, finding bugs, and suggesting improvements
- Function- or system-focused testing
- Quest, zone, ability, item, and UI testing
- Balance and gameplay feedback
- JASS/code review, debugging, and optimization
- Proofreading dialogue, quest text, tooltips, and other written content
- Helping identify missing resource credits

Basically in every aspect of the development and testing. Send me a message (Valdemar) if you are interested.

</details>

<details>
<summary><strong>FAQ: Will there be multiplayer functionality for two or more players?</strong></summary>
This is something I wanted for a long time. The original idea was to have a co-op mode where Nazgrek and Zul'kis could either both be controlled by one player or be split between two players.
Unfortunately, many of the map's older systems were designed with only one player in mind. Supporting multiplayer properly would therefore require significant reworking of existing systems, so I eventually made the decision to scrap the multiplayer version and focus on the single-player experience.
That said, I have tried to make many of the newer systems work with more than one player where reasonably possible, in case I ever decide to revisit multiplayer in the future.
</details>

<details>
<summary><strong>FAQ: Why is the map written in JASS and not Lua?</strong></summary>
I did try converting the project to Lua, but I ran into too many problems during the conversion. This included converting my own systems as well as adapting systems originally made by other people, and troubleshooting the resulting issues became a nightmare.
I also prefer JASS's type checking and syntax. For me, it makes the code easier to reason about and helps catch mistakes earlier, so I ultimately decided to continue developing Path of the Shaman in JASS.
</details>

<details>
<summary><strong>FAQ: Why not make a campaign with multiple maps, such as separate dungeons and larger zones, like Blizzard's Rexxar campaign?</strong></summary>
That is actually how Path of the Shaman originally started.
Back around 2006-2008, when I first began creating the project, it was a Warcraft III campaign. At the time, however, I lacked the knowledge needed to properly handle things such as transitioning between maps, preserving heroes and items, and transferring other persistent game data.
I later converted the campaign into a single map when I started developing the project with multiplayer in mind.
The project has since grown around that single-map architecture, and changing it back into a multi-map campaign would now require substantial restructuring.
</details>

<details>
<summary><strong>FAQ: Has AI been used in the development of Path of the Shaman?</strong></summary>
Yes.

AI has been used as a development tool in several areas of the project. This includes generating voices and assisting with the development, debugging, and improvement of many of my own systems.

I believe AI can be useful for helping people move forward with projects that would otherwise be difficult or extremely time-consuming to create alone. However, using AI does not make a project of this scale automatic. There is still a large amount of work involved in designing systems, deciding how everything should work, integrating different parts of the project, testing, debugging, maintaining consistency, and generally orchestrating the whole project.

Voice work is a good example. I can and want to record many voice lines myself, but Path of the Shaman contains more than 1,000 individual voice files across hundreds of different voices. Producing all of those manually by myself—or even organizing enough recruited voice actors to cover everything—would be a very large undertaking.
AI therefore acts as another development tool rather than replacing the overall creative and technical work behind the project.

There's naturally huge work to manually review and change many voicelines, because sometimes my ideas don't get through as I intended - many times i re-write everything, but atleast I have "template" ready...
</details>

<details>
<summary><strong>FAQ: My name is not credited. What should I do?</strong></summary>
Send me a message if your name is missing from the credits for a resource used by Path of the Shaman.
Foolishly, I did not keep proper track of every resource and author from the beginning of development. I am therefore gradually backtracking the resources used by the project and updating the credits list as I identify them.
</details>