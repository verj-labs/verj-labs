export type City = {
  id: string;
  name: string;
  country: string;
  lon: number;
  lat: number;
  src: string;
  width: number;
  height: number;
  alt: string;
  story: string;
  credit: { title: string; creator: string; license: string; licenseUrl: string; page: string };
};

export type Work = {
  id: string;
  name: string;
  kind: string;
  year: string;
  group: string;
  cityId: string;
  traceId: string | null;
  lead: boolean;
  outcome: string;
  href?: { label: string; url: string };
};

export type Hop = { short: string; what: string; detail: string };

export type Trace = {
  id: string;
  name: string;
  blurb: string;
  groups: { heading: string; hops: Hop[] }[];
  result: string;
};

export const MAIL = "mailto:mr.wrehmani@gmail.com?subject=Hello%20Waqas";
export const PHONE = "tel:+14373358449";
export const PHONE_LABEL = "+1 437 335 8449";

export const CITIES: City[] = [
  {
    id: "ankara",
    name: "Ankara",
    country: "Turkey",
    lon: 32.85,
    lat: 39.93,
    src: "/places/ankara.jpg",
    width: 1920,
    height: 1224,
    alt: "Ankara Castle on a rocky green hill, with the Turkish flag flying above the walls.",
    story:
      "Bachelor of Computer Science at Bilkent University, with high honours. The degree started here. An exchange at NTU took him to Singapore before it was finished.",
    credit: {
      title: "Ankara Castle",
      creator: "Bernard Gagnon",
      license: "CC BY-SA 3.0",
      licenseUrl: "https://creativecommons.org/licenses/by-sa/3.0",
      page: "https://commons.wikimedia.org/wiki/File:Ankara_Castle.jpg",
    },
  },
  {
    id: "singapore",
    name: "Singapore",
    country: "Singapore",
    lon: 103.85,
    lat: 1.29,
    src: "/places/singapore.jpg",
    width: 1920,
    height: 1440,
    alt: "The Singapore River, with shophouses along the bank and towers behind them.",
    story:
      "An exchange term at NTU, during the Bilkent years. Later he worked for Coda Payments, a company based here. That role was remote: campaign setup went from four days to fifteen minutes, and a catalogue system he led took processing from ten days to hours.",
    credit: {
      title: "Hus längs Singapore River",
      creator: "Johan Jönsson",
      license: "CC BY-SA 4.0",
      licenseUrl: "https://creativecommons.org/licenses/by-sa/4.0",
      page: "https://commons.wikimedia.org/wiki/File:Hus_l%C3%A4ngs_Singapore_River.jpg",
    },
  },
  {
    id: "melbourne",
    name: "Melbourne",
    country: "Australia",
    lon: 144.96,
    lat: -37.81,
    src: "/places/melbourne.jpg",
    width: 1920,
    height: 1438,
    alt: "Flinders Street Station in Melbourne at night, its dome lit above the intersection.",
    story:
      "Master of Software Engineering at the University of Melbourne, with high honours. A second country, a second degree, and the same habit of finishing the work.",
    credit: {
      title: "Flinders Street Railway Station, Melbourne",
      creator: "Dietmar Rabich",
      license: "CC BY-SA 4.0",
      licenseUrl: "https://creativecommons.org/licenses/by-sa/4.0",
      page: "https://commons.wikimedia.org/wiki/File:Melbourne_(AU),_Flinders_Street_Railway_Station_--_2019_--_202623.jpg",
    },
  },
  {
    id: "karachi",
    name: "Karachi",
    country: "Pakistan",
    lon: 67.01,
    lat: 24.86,
    src: "/places/karachi.jpg",
    width: 1920,
    height: 1258,
    alt: "Fishing boats in Karachi harbour, blue hulls and green flags on the water.",
    story:
      "Trakart, January 2021 to June 2022. He was technical co-founder. The product was a creative networking platform, fully serverless: AWS Lambda, DynamoDB and Node.js.",
    credit: {
      title: "Fishing boats at Karachi Harbour",
      creator: "Shayanshaukat",
      license: "CC BY-SA 3.0",
      licenseUrl: "https://creativecommons.org/licenses/by-sa/3.0",
      page: "https://commons.wikimedia.org/wiki/File:FishingshipsatKarachiHarbour.JPG",
    },
  },
  {
    id: "waterloo",
    name: "Waterloo",
    country: "Canada",
    lon: -80.52,
    lat: 43.46,
    src: "/places/waterloo.jpg",
    width: 1920,
    height: 1335,
    alt: "Uptown Waterloo, Ontario, a street of brick and glass buildings seen from above.",
    story:
      "Arctic Wolf, December 2024 to May 2026, hybrid, on a security platform. Verily Health from August 2026, as a software engineer. Home is Milton, close by. Verj Labs is run from there, beside the day job. The photograph is the town, not an office.",
    credit: {
      title: "Uptown Waterloo Ontario",
      creator: "Giligone",
      license: "CC BY-SA 3.0",
      licenseUrl: "https://creativecommons.org/licenses/by-sa/3.0",
      page: "https://commons.wikimedia.org/wiki/File:Uptown_Waterloo_Ontario.JPG",
    },
  },
];

export const ROUTE = ["ankara", "singapore", "melbourne", "karachi", "waterloo"];

export const WORK: Work[] = [
  {
    id: "verily",
    name: "Verily Health",
    kind: "Software engineer",
    year: "2026",
    group: "2026",
    cityId: "waterloo",
    traceId: null,
    lead: true,
    outcome:
      "Software engineer at Verily Health in Waterloo, since August 2026. This is the day job.",
  },
  {
    id: "wolf",
    name: "Arctic Wolf",
    kind: "Security platform",
    year: "2024",
    group: "2024",
    cityId: "waterloo",
    traceId: "review",
    lead: false,
    outcome:
      "Senior software developer, December 2024 to May 2026. An AI review workflow cut the team’s cycle time by more than half, on a security platform with more than 700 internal users and more than 10,000 external ones.",
  },
  {
    id: "verj",
    name: "Verj Labs",
    kind: "Studio, on the side",
    year: "2024",
    group: "2024",
    cityId: "waterloo",
    traceId: null,
    lead: false,
    outcome:
      "Technical co-founder of Verj Labs, from September 2024. The studio runs beside the day job.",
    href: { label: "verjlabs.com", url: "https://verjlabs.com" },
  },
  {
    id: "dealrdash",
    name: "DealrDash",
    kind: "Dealer platform",
    year: "2024",
    group: "2024",
    cityId: "waterloo",
    traceId: "dealrdash",
    lead: false,
    outcome:
      "A platform for independent car dealers: inventory, leads, deals and documents. Built in about three weeks. A side business, not the day job.",
    href: { label: "dealrdash.com", url: "https://dealrdash.com" },
  },
  {
    id: "zavara",
    name: "Zavara Studio",
    kind: "Product photography",
    year: "2024",
    group: "2024",
    cityId: "waterloo",
    traceId: "zavara",
    lead: false,
    outcome:
      "Product photography for jewelers, generated with Gemini Flash Image. A separate prototype plans a short ad, animates it and stitches the cut.",
    href: { label: "zavarastudio.com", url: "https://zavarastudio.com" },
  },
  {
    id: "ta",
    name: "Virtual TA",
    kind: "Study assistant",
    year: "2024",
    group: "2024",
    cityId: "waterloo",
    traceId: "ta",
    lead: false,
    outcome:
      "A study assistant for A-level students. The curriculum sits in ChromaDB. The model answers in one of three ways: simply, like an exam, or around what the student cares about.",
  },
  {
    id: "halal",
    name: "Halal Compass",
    kind: "Directory",
    year: "2024",
    group: "2024",
    cityId: "waterloo",
    traceId: null,
    lead: false,
    outcome:
      "A directory of halal restaurants, mosques and events, on the web and on a phone. It shipped. It is no longer live.",
  },
  {
    id: "coda",
    name: "Coda Payments",
    kind: "4 days to 15 minutes",
    year: "2022",
    group: "2022",
    cityId: "singapore",
    traceId: "campaign",
    lead: true,
    outcome:
      "Software engineer, July 2022 to August 2024, remote for a Singapore company. Campaign setup went from four days of scripts to fifteen minutes. A catalogue system he led took processing from ten days to hours.",
  },
  {
    id: "trakart",
    name: "Trakart",
    kind: "Co-founder",
    year: "2021",
    group: "2021",
    cityId: "karachi",
    traceId: null,
    lead: true,
    outcome:
      "Technical co-founder in Karachi, January 2021 to June 2022. A creative networking platform on AWS Lambda, DynamoDB and Node.js.",
  },
  {
    id: "melbourne",
    name: "Melbourne",
    kind: "Master’s, high honours",
    year: "2019",
    group: "2019",
    cityId: "melbourne",
    traceId: null,
    lead: true,
    outcome: "Master of Software Engineering at the University of Melbourne, high honours.",
  },
  {
    id: "bilkent",
    name: "Bilkent",
    kind: "Bachelor’s, high honours",
    year: "2014",
    group: "2014",
    cityId: "ankara",
    traceId: null,
    lead: true,
    outcome:
      "Bachelor of Computer Science at Bilkent University, high honours, with an exchange at NTU in Singapore.",
  },
];

export const TRACES: Trace[] = [
  {
    id: "campaign",
    name: "Campaign setup",
    blurb: "At Coda, a campaign used to be a pile of scripts. He built the tool that replaced them.",
    groups: [
      {
        heading: "Before",
        hops: [
          { short: "The ask", what: "Someone needs a campaign live", detail: "Request" },
          { short: "Scripts", what: "The old setup was written by hand", detail: "4 days" },
        ],
      },
      {
        heading: "The tool",
        hops: [{ short: "One path", what: "The tool runs the setup from end to end", detail: "Built" }],
      },
      {
        heading: "After",
        hops: [{ short: "Ready", what: "The campaign is ready to run", detail: "15 min" }],
      },
    ],
    result: "Four days of setup now takes fifteen minutes.",
  },
  {
    id: "catalogue",
    name: "Catalogue",
    blurb: "The same team at Coda. Catalogue changes were sitting in a queue for ten days.",
    groups: [
      {
        heading: "In",
        hops: [{ short: "A change", what: "A catalogue change enters the queue", detail: "SKU" }],
      },
      {
        heading: "Before",
        hops: [{ short: "The wait", what: "The old processing took ten days", detail: "10 days" }],
      },
      {
        heading: "After",
        hops: [{ short: "Hours", what: "The system he led clears the same change", detail: "Hours" }],
      },
    ],
    result: "Ten days of processing now takes hours. He connects that to an estimated $1.2 million a month.",
  },
  {
    id: "review",
    name: "Review workflow",
    blurb: "At Arctic Wolf, the slow part of the week was review. He put an AI pass next to the author, and left the author in charge.",
    groups: [
      {
        heading: "Open",
        hops: [{ short: "A change", what: "A pull request opens on the platform", detail: "Review" }],
      },
      {
        heading: "Assist",
        hops: [{ short: "AI pass", what: "A model reviews the change and drafts code", detail: "AI" }],
      },
      {
        heading: "Ship",
        hops: [
          { short: "The author", what: "The person still owns what ships", detail: "Human" },
          { short: "Faster", what: "The team’s cycle time falls by more than half", detail: "Half" },
        ],
      },
    ],
    result: "Cycle time cut by more than half, on a platform with 700 internal users and 10,000 external ones.",
  },
  {
    id: "dealrdash",
    name: "DealrDash",
    blurb:
      "One dealer’s world, sealed off from the next. He has also been building a chatbot that answers from that dealer’s inventory and FAQ.",
    groups: [
      {
        heading: "Tenant",
        hops: [{ short: "One dealer", what: "The dealer works inside their own tenant", detail: "Tenant" }],
      },
      {
        heading: "The work",
        hops: [
          { short: "The desk", what: "Inventory, leads, deals and documents live together", detail: "Product" },
          { short: "The site", what: "The public site stays in step with inventory", detail: "Sync" },
        ],
      },
      {
        heading: "Ask",
        hops: [{ short: "Questions", what: "A chatbot reads that dealer’s own inventory and FAQ", detail: "Retrieval" }],
      },
    ],
    result: "Live at dealrdash.com. About three weeks to build, beside the day job.",
  },
  {
    id: "zavara",
    name: "Zavara photos",
    blurb: "Jewelers were waiting days for CAD and a photo studio. The shipped piece is the photograph.",
    groups: [
      {
        heading: "Ask",
        hops: [{ short: "A piece", what: "A jeweler needs a picture of a piece", detail: "Brief" }],
      },
      {
        heading: "Picture",
        hops: [{ short: "Gemini", what: "Gemini Flash Image generates the photograph", detail: "Gemini" }],
      },
      {
        heading: "Live",
        hops: [{ short: "Studio", what: "The picture lands in the studio the jeweler uses", detail: "Shipped" }],
      },
    ],
    result: "Product photography in minutes. Live at zavarastudio.com.",
  },
  {
    id: "ad",
    name: "Ad prototype",
    blurb: "A second pipeline, prototyped beside the photography. Several models, one short film. This cut is a prototype.",
    groups: [
      {
        heading: "Plan",
        hops: [{ short: "Director", what: "A model plans the scenes and the music", detail: "Plan" }],
      },
      {
        heading: "Make",
        hops: [
          { short: "Frames", what: "Gemini generates the frames", detail: "Gemini" },
          { short: "Motion", what: "Kling animates those frames", detail: "Kling" },
        ],
      },
      {
        heading: "Cut",
        hops: [{ short: "Stitch", what: "The frames and the motion become a short ad", detail: "30s" }],
      },
    ],
    result: "A prototype of a thirty-second ad. The photography is the part that shipped.",
  },
  {
    id: "ta",
    name: "Virtual TA",
    blurb: "A study assistant for A-level students. One corpus, three ways of answering.",
    groups: [
      {
        heading: "Library",
        hops: [{ short: "Curriculum", what: "The course material is embedded for retrieval", detail: "Chroma" }],
      },
      {
        heading: "Ask",
        hops: [
          { short: "Question", what: "A student asks in the app", detail: "App" },
          { short: "Passages", what: "The relevant pages come back", detail: "Retrieve" },
        ],
      },
      {
        heading: "Answer",
        hops: [{ short: "One mode", what: "The model explains it simply, like an exam, or around the student’s interests", detail: "Three" }],
      },
    ],
    result: "OpenAI, NestJS and React Native. Three answers from one curriculum.",
  },
];

export const PROOF = [
  "DealrDash",
  "Zavara Studio",
  "Halal Compass",
  "Virtual TA",
  "Coda Payments",
  "Trakart",
];

export function cityById(id: string) {
  return CITIES.find((c) => c.id === id) ?? CITIES[0];
}

export function workById(id: string) {
  return WORK.find((w) => w.id === id) ?? WORK[0];
}

export function traceById(id: string) {
  return TRACES.find((t) => t.id === id) ?? TRACES[0];
}

export function hopsOf(trace: Trace) {
  return trace.groups.flatMap((g) => g.hops);
}
