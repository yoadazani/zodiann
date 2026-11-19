# ZOD-FND-010: Swiss Ephemeris license decision record

> **Status: DECIDED 2026-11-19 (path A, AGPL), to be reconfirmed by ZOD-REL-003 against the distribution channel.** Researched and drafted 2026-11-19 (ZOD-FND-010).
>
> **This is not legal advice.** It is a reading of published terms by a software engineer. Each statement is labelled **Confirmed** (read in a cited source on the date shown), **Interpretation** (my reading of confirmed facts, which could be wrong) or **Open** (not settled by the sources; a question for Astrodienst or a qualified lawyer). Nothing was purchased, signed or sent to anyone.

## 1. Question

Zodiann (Flutter, iOS and Android, spec R-6) wants Swiss Ephemeris as its primary position source. The library is offered under two licenses; which one applies decides whether the app's source must be published, whether money is owed, and where the app may be distributed. This record covers the product owner's stated situation (2026-11-19): a **public GitHub repository**, installation packages built for the owner and **one friend**, personal use only, **no sale or commercial distribution intended**. Distribution through Google Play or the Apple App Store is **not decided here** (ZOD-REL-003 owns the channel, decision D1); section 6 says what changes if it happens.

What depends on it: ZOD-FND-003 (the FFI spike vendors the C source), ZOD-FND-011 (data-file range), ZOD-EPH-002 / 003 (adapters), ZOD-ABT-007 (the About screen's license text), ZOD-REL-003 (channel and final license path).

Current state of the repository (**Confirmed**, `gh repo view` and `ls`, 2026-11-19): the repository `yoadazani/zodiann` is **public**, GitHub reports **no license** for it (`licenseInfo: null`), there is **no LICENSE file**, and **no Swiss Ephemeris code is vendored yet** (`native/swisseph/` holds only a README). So no license obligation has been triggered so far.

## 2. Sources

All read on **2026-11-19**. "Single" = only one source for the fact.

| # | Source | URL | Supports |
|---|---|---|---|
| S1 | Astrodienst, Swiss Ephemeris general information | https://www.astro.com/swisseph/swephinfo_e.htm | the dual license, how to obtain each edition |
| S2 | Astrodienst, price list and order | https://www.astro.com/swisseph/swephprice_e.htm | price: Free Edition CHF 0.00, Professional Edition unlimited license CHF 700.00 |
| S3 | Astrodienst, Professional License contract (PDF, "Edition September 2026 update 9 Nov 2026") | https://www.astro.com/swisseph/secont_e_2609.pdf | exact Professional License terms |
| S4 | Swiss Ephemeris GitHub repository: `LICENSE`, `readme.md`, `ephe/` (release `v2.10.3bfinal`, 2026-08-02) | https://github.com/aloistr/swisseph | the license notice shipped with the source; the data files are in the public repo |
| S5 | Astrodienst, Swiss Ephemeris general documentation (© 1997-2022) | https://www.astro.com/swisseph/swisseph.htm | an older price statement (see 4.2) |
| S6 | GNU AGPL v3 text | https://www.gnu.org/licenses/agpl-3.0.txt | what AGPL requires |
| S7 | FSF, GNU licenses FAQ | https://www.gnu.org/licenses/gpl-faq.html | private use, "convey", the FSF's reading |
| S8 | FSF, "GPL Enforcement in Apple's App Store" (2010) | https://www.fsf.org/news/2010-05-app-store-compliance | the FSF's position on the App Store |
| S9 | FSF's Brett Smith on the VLC list (2010-11-02) | https://mailman.videolan.org/pipermail/vlc-devel/2010-November/077044.html | what happens to users who already hold a copy |
| S10 | `sweph` Dart/Flutter package (pub.dev, version 4.1.0+2.10.3, published 2026-09-03) | https://pub.dev/packages/sweph | how the existing Dart binding is licensed |
| S11 | Astronomy Engine `README.md` and `LICENSE` (repo `cosinekitty/astronomy`, latest release v2.1.19, 2023-12-14) | https://github.com/cosinekitty/astronomy | license, accuracy, bodies, languages |
| S12 | Zodiann specification (`assets/zodiann-specification.md`), "Astronomical accuracy" and ACC-1 / ACC-2 | in this repository | the accuracy the product requires |
| S13 | Signal-Android and Signal-iOS `LICENSE` files | https://github.com/signalapp/Signal-Android , https://github.com/signalapp/Signal-iOS | examples of AGPL-3.0 mobile apps |
| S14 | Google Play listing of Signal | https://play.google.com/store/apps/details?id=org.thoughtcrime.securesms | the app is listed on Google Play (page title "Signal Private Messenger - Apps on Google Play", HTTP 200) |
| S15 | LWN, "FSF takes on Apple's App Store over GPL" (secondary) | https://lwn.net/Articles/391423/ | background only (fetched; it reports Apple removed the game rather than change its policies) |

Not obtained: Apple's current App Store terms and standard end-user license (the fetch failed), any Astrodienst statement about app stores or closed-source mobile apps (none found in S1-S5), and a lawyer's view.

## 3. The two licenses, as Astrodienst states them

**Confirmed (S1, S4 `LICENSE`).** Swiss Ephemeris is "made available by its authors under a dual licensing system". A developer who "uses any part of Swiss Ephemeris in his or her software must choose between one of the two license models": (a) the GNU Affero General Public License, or (b) the Swiss Ephemeris Professional License. "The choice must be made before the software developer distributes software containing parts of Swiss Ephemeris to others, and before any public service using the developed software is activated." Choosing AGPL "includes the obligation to place his or her whole software project under the AGPL or a compatible license". Both license types include the right to use the label "Swiss Ephemeris Inside" (S1). The authors' names may not be used to promote the software (S1, S3 section 9).

**Confirmed (S1, S2).** The "Free Edition" costs CHF 0.00 and is downloaded from GitHub (S4). The "Professional Edition unlimited license" costs **CHF 700.00**; "only the license is sold", and the software and data are downloaded from the public GitHub repository. The vendor says the amount is converted at current rates to EUR or USD (no converted figure was read, so none is given here).

**Confirmed (S4).** The repository holds the C source and the compressed `.se1` data files; the readme says the planet and asteroid files were rebuilt on JPL DE441 on 14 April 2026, and S1 states a covered range of 13201 BC to AD 17191.

## 4. Option A: AGPL (the Free Edition), for the owner's scenario

### 4.1 What AGPL requires (all **Confirmed** from S6 unless marked)

- **Using it yourself is free of conditions.** AGPL defines "propagate" as anything that, without permission, would make you liable for infringement, "except executing it on a computer or modifying a private copy". The FSF FAQ (S7) says you may make and use modifications privately and need release nothing.
- **The duties start when you "convey".** "To 'convey' a work means any kind of propagation that enables other parties to make or receive copies." Giving the friend an installation package (a copy of the object code) is conveying. "Mere interaction with a user through a computer network, with no transfer of a copy, is not conveying." (Zodiann has no server, so the AGPL section 13 network clause, which concerns remote interaction with a modified version, is not engaged by the current design. Interpretation.)
- **Conveying object code requires the Corresponding Source** (section 6): either with the package, or by a written offer, or (6d) by "offering access from a designated place" and offering "equivalent access to the Corresponding Source in the same way through the same place at no further charge"; if the place is a network server, "the Corresponding Source may be on a different server ... provided you maintain clear directions next to the object code saying where to find the Corresponding Source", and "you remain obligated to ensure that it is available for as long as needed to satisfy these requirements".
- **"Corresponding Source" is complete:** "all the source code needed to generate, install, and (for an executable work) run the object code and to modify the work, including scripts to control those activities", including source for libraries the work is specifically designed to require.
- **The whole work is under AGPL, and no further restrictions** may be added: you "may not impose any further restrictions on the exercise of the rights granted" (section 10), and the recipient automatically receives a license from the original licensors (section 10).
- **Astrodienst's own reading (S1, S4):** the whole project goes under "the AGPL or a compatible license".

### 4.2 Does a public repository satisfy this? (**Interpretation**, with the confirmed facts it rests on)

**Short answer: a public repository is the right vehicle for the source obligation, but being public is not by itself sufficient.** Four things would have to hold:

1. **The repository must actually be licensed AGPL (or compatible).** *Confirmed:* it is public today with **no license**. Visible source is not the same as a granted AGPL license; AGPL requires the whole project to be placed under it. Adding the license (a LICENSE file and notices) is a project action that needs your approval; it is not done here.
2. **The source must match what the friend receives.** The Corresponding Source is the source of the version conveyed, with the scripts to build and install it. In practice: build each package from a tagged commit, and keep that tag public. A repository that moves on after the package was handed over does not by itself break this, provided the matching tag stays available (6d: "for as long as needed").
3. **Clear directions next to the package** saying where the source is (for example the repository URL and tag in the About screen and in the message that carries the package). *Confirmed:* 6d asks for "clear directions next to the object code".
4. **Everything the app is built from must be compatible with AGPL and published as needed.** *Not verified in this task:* the licenses of Flutter, Riverpod, go_router, drift, `astronomy` and the bundled fonts (IBM Plex, Noto, under the SIL OFL) against AGPL. ZOD-ABT-007 builds the license list; a compatibility check belongs with it. *Confirmed:* the existing Dart binding `sweph` is **AGPL-3.0-only by default** and offers an LGPL grant only to holders of a Professional License (S10).

**Interpretation:** for two people, private use and a public repository, Option A looks workable and costs nothing, **provided items 1 to 4 are done**. It also sits naturally with a public repository, since Option A obliges you to publish the source anyway. **Open:** whether the `.se1` data files are covered by the AGPL grant in the same way as the C source. The LICENSE notice speaks of "any part of Swiss Ephemeris" (S1, S4), and the Professional contract lists the data files as a part of the library (S3 section 1), but no source states the free-edition position on the data files in terms. Question Q2.

### 4.3 Practical consequences of choosing A

- You can never later keep the app closed-source while Swiss Ephemeris is AGPL-licensed inside it, unless you switch to the Professional License (which Astrodienst sells to anyone, S2, S3).
- The friend, as a recipient, gets AGPL rights to run, modify and pass it on (section 10). You cannot restrict that.
- A license change to Professional later is possible (section 5.1 below); nothing in the sources says an earlier AGPL release must be withdrawn. **Open**, Q4.

## 5. Option B: the Swiss Ephemeris Professional License

### 5.1 Terms (**Confirmed**, S2 and S3, edition September 2026)

- **Price:** CHF 700.00, "for an unlimited number of projects developed and/or maintained by the licensee" (S3 preamble, S2).
- **Duration:** "A license is valid for 6 years. It then has to be renewed or the use of Swiss Ephemeris in web services or distributed software has to be terminated." The renewal fee "will be not more than the original fee, possibly adjusted for accumulated inflation rate in Switzerland. It is likely that from 2030 or earlier an annual subscription model at comparable cost will be offered" (S3 sections 4, 16; the subscription is the vendor's expectation, not a commitment).
- **Scope:** "valid for distributed software apps" whose copyright the licensee holds; an app that fetches calculations from a server also counts as an app containing Swiss Ephemeris; server-side use through a browser is also covered (S3 section 2).
- **Source code:** "permitted, but not required" to distribute the Swiss Ephemeris source with the app; if distributed, the complete source, and changes to it fall under AGPL terms (S3 section 5).
- **Other terms:** API services to third parties need those third parties' own licenses (S3 section 3); the licensee must give Astrodienst a sample copy of an app on request, for Astrodienst's internal use (section 7); the authors' names must not be used (section 9); copyright notices must stay (section 10); the license is transferable by telling Astrodienst (section 15); the license is valid only after full payment through the shop (section 14); venue is Meilen, canton of Zurich (section 17); bindings must also be available under both licenses with no extra fee (section 13); the data files are part of what is licensed (section 1).
- **Stale price elsewhere:** the general documentation (S5, © 1997-2022) still says CHF 750 for the first license, CHF 400 for each additional one, CHF 1550 unlimited. The price page and the contract (S2, S3) both say CHF 700 unlimited and are newer. The record uses S2 and S3.

### 5.2 Does it help for the owner's scenario? (**Interpretation**)

**Not meaningfully, today.** Its benefits are (a) the app's own code may stay closed-source and (b) a clear commercial footing for broader distribution. For two private users with a public repository, (a) has no value (the source is public by choice), and nothing in the sources suggests a restriction on a private two-person use under AGPL. It costs CHF 700 and renews after six years. It becomes relevant if the app is to be sold, kept closed, or put into a store whose terms conflict with AGPL (section 6).

## 6. If Zodiann is later distributed more widely or commercially (**not decided here**: ZOD-REL-003)

- **Selling under AGPL is permitted in principle** (AGPL section 4: "You may charge any price or no price for each copy that you convey", S6), but every buyer receives the AGPL rights and the source obligations stay.
- **Google Play.** *Confirmed:* Signal's Android code is AGPL-3.0 (S13) and the app is listed on Google Play (S14). *Interpretation:* that shows an AGPL app can be listed there; it does not say whether Astrodienst-owned AGPL code can be, since Signal owns its own code. No source read says Google Play's terms conflict with AGPL. **Open.**
- **Apple App Store.** *Confirmed:* in 2010 the FSF stated that an iPhone GNU Go port was "not in compliance with the GNU GPL" because "Apple imposes numerous legal restrictions on use and distribution ... through the iTunes Store Terms of Service", which GPLv2 forbids; Apple then removed the app (S8, S15). The FSF added that "Apple is free to distribute our software through the App Store if they wish". *Contested:* commentators dispute the FSF reading (S15, informal). *Not obtained:* Apple's current terms (the fetch failed), and an up-to-date source on whether GPL or AGPL code by third-party copyright holders is accepted today. Signal-iOS is AGPL-3.0 (S13); whether it is on the App Store was not verified here. *Interpretation:* distributing Astrodienst-owned AGPL code through the App Store is **unresolved by the sources I read**, and the Professional License (S3 section 2, "distributed software apps") is the route Astrodienst itself offers for apps. **Open**, Q3.
- **Commercial or closed-source use** needs the Professional License (S1: AGPL means "the whole software project" under AGPL).
- **If the owner publishes broadly under AGPL** the AGPL section 13 network clause matters only if a server-side component is added later (Interpretation).

## 7. Option C: leave Swiss Ephemeris for Astronomy Engine

**Confirmed (S11).** Astronomy Engine is **MIT-licensed**. Its README says it is "designed to be small, fast, and accurate to within ±1 arcminute", and it computes the Sun, Moon, Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune and Pluto. It is published for C, C#, JavaScript, Python and Kotlin; the C version is the one the spec plans to call through FFI. Latest release v2.1.19 (2023-12-14); the repository's last push read was 2025-01-27. No Dart package named for it appeared in two pub.dev searches (not exhaustive).

**Confirmed (S12, the spec).** The product requires a position "within one arcsecond of the reference data" (ACC-1, "Allowed deviation for each body: one arcsecond"), a degree-crossing threshold of 0.01 arcseconds in longitude (CRS-A3), and classes Swiss Ephemeris as "sub-arcsecond" primary and Astronomy Engine as a backup "on the order of an arcminute or better ... less accurate than the primary source" (ACC-2 tolerance: one arcminute).

**Interpretation.** One arcminute is 60 arcseconds, so by its own stated accuracy Astronomy Engine **is not an equivalent replacement**: it would fail ACC-1 by design, so choosing it would mean changing the product's accuracy requirement (a specification change for the product owner, not an engineering swap). Its accuracy figure is also a claim from its own README; I did not test it. Migration touches ZOD-EPH-002 / 003 / 005, the crossing tasks (error in crossing time grows as position error over speed, worst near stations), the accuracy tests (ACC-1 to ACC-3) and dropping the data-file work (FND-011). The mean lunar node is already the project's own formula (ZOD-EPH-001) either way. It removes every license question (MIT), but at an accuracy cost the spec does not accept. This option is **outside this task** and would be raised separately.

## 8. Findings the sources do not settle, and drafted questions

For the owner to send to Astrodienst (`order@astro.com` is the address S1 gives for the contract; the mailing list is S4's `groups.io/g/swisseph`). A lawyer's view is the better answer to Q3. **Nothing has been sent.**

> **Q1 (private sharing).** We are developing a mobile app (Flutter, iOS and Android) that would call Swiss Ephemeris through FFI, with the full source of the app public on GitHub under the AGPL. We intend to give installation packages to one friend for personal use and not to sell or publicly distribute it. Can you confirm that the AGPL Free Edition is sufficient for this, and that publishing the source repository (tagged to the version of each package we hand over) satisfies the AGPL source obligation?
>
> **Q2 (data files).** Are the `.se1` ephemeris data files in your GitHub repository licensed under the same AGPL grant as the C source for a Free Edition user, or under different terms? May they be bundled inside an app package we hand to a friend?
>
> **Q3 (stores).** If an app that uses the AGPL Free Edition is later published on the Apple App Store or Google Play, do you consider that compatible with your AGPL grant (given Apple's App Store terms), or do you require the Professional License for store distribution? Would you grant an additional permission for store distribution under AGPL?
>
> **Q4 (switching).** If we release builds under AGPL now and buy the Professional License later, do you consider the earlier AGPL releases still validly licensed?

Questions I cannot answer from the sources and that belong to a lawyer: whether any statute or contract term of the stores overrides the above, and whether the SIL OFL fonts and other dependencies are compatible with an AGPL project (Open, section 4.2 item 4).

## 9. Recommendation (a recommendation only; the decision is the owner's)

Based on the stated use (public repository, one friend, personal, no sale) and **independent of the distribution channel, which REL-003 decides**:

- **Choose Option A, AGPL, for now.** It costs nothing, matches a public repository, and nothing read suggests that sharing a package with one friend is a problem **provided** the repository is actually put under the AGPL (it is not today), each package is built from a public tag, and the source location is stated next to the package. **Do not buy the Professional License now:** it adds no benefit for this use.
- **Before the first package that contains Swiss Ephemeris is handed to anyone**, the choice must be made and the repository licensed accordingly (S1: the choice comes "before the software developer distributes" it). That follow-up (adding the AGPL license and notices, and the About screen text via ZOD-ABT-007) is not part of this record and needs the owner's approval.
- **Revisit at ZOD-REL-003** if the app is to go to the App Store, to be sold, or to be closed-source: then Q3 should be answered, or the Professional License (CHF 700, 6 years, S2 and S3) bought, before any store submission. Option C would need a separate accuracy decision (section 7).
- If the owner wants certainty first, send Q1 and Q2; they are cheap, and the answers fit the choice either way.

## 10. Decision

**Decided by the product owner on 2026-11-19: Option A, the AGPL (Free Edition) path, for now.** The owner was shown the options and the recommendation (section 9) and chose the recommended path. Nothing was purchased and nothing was sent to Astrodienst.

**Why:** the stated use is a public repository, installation packages for the owner and one friend, personal use, no sale. Option A costs nothing, fits a public repository, and the sources read give no sign that this use is a problem; the Professional License (CHF 700, 6 years) gives no meaningful benefit for it.

**What follows (obligations the owner now carries; none is done by this task, each needs the owner's approval before it is carried out):**

1. Before the first package that contains Swiss Ephemeris is given to anyone, put the whole repository under the AGPL (a `LICENSE` file and notices); today it is public with no license (section 1, 4.2).
2. Build each package from a tagged commit and keep the tag public; state next to the package where the source is (section 4.2 items 2 and 3).
3. ZOD-ABT-007: the Swiss Ephemeris chip shows the AGPL path (attribution and the source location), not a commercial-license text; check the other dependencies and fonts for AGPL compatibility there (section 4.2 item 4, open).
4. ZOD-FND-003 vendors the source from the public repository `aloistr/swisseph` (release v2.10.3bfinal at the time of reading) and records the version; it should use the AGPL-licensed bindings and keep the notices intact (the `sweph` Dart package is AGPL-3.0-only by default).
5. The questions Q1 to Q4 (section 8) stay available for the owner to send; none was sent.

**Channel and reconfirmation:** the distribution channel is **not** decided here. ZOD-REL-003 owns it and confirms the final path against the channel it picks. If the app is to go to the Apple App Store or Google Play, be sold, or be closed-source, this decision must be revisited then: Q3 answered or the Professional License bought before any store submission (section 6). Switching later is possible but its effect on earlier AGPL releases is open (Q4).
