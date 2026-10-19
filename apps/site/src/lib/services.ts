import { NeedId } from "./site";

export type Service = {
  id: NeedId;
  code: string;
  title: string;
  lead: string;
  examples?: string[];
  gets: string[];
  time: string;
};

export const SERVICES: Service[] = [
  {
    id: "ai",
    code: "S-01",
    title: "AI for your business",
    lead: "Put AI to work where it saves you real time. We add it to the tools you already use, or build something new around it.",
    examples: [
      "Answers from your own documents. Ask questions in plain language and get answers based on your files.",
      "Automate repetitive work. Let AI draft, sort and route the tasks nobody enjoys.",
      "Generate content. Product copy, images and videos created in minutes instead of days.",
      "Search that understands you. Find what you need even when you do not know the exact words.",
    ],
    gets: [
      "The right AI model chosen for the job",
      "AI connected to your own data and tools",
      "AI added to a product you already have",
      "Testing of the quality of its answers",
    ],
    time: "2 to 6 weeks",
  },
  {
    id: "product",
    code: "S-02",
    title: "A new software product",
    lead: "Have an idea for an app, a platform or an internal system? We take it from idea to a live product people can use.",
    gets: ["A clear technical plan", "Design and a full build", "Cloud hosting set up and ready", "Improvements after launch"],
    time: "6 to 16 weeks",
  },
  {
    id: "web",
    code: "S-03",
    title: "A website or web platform",
    lead: "A custom site or platform that looks sharp, loads fast and that you can edit yourself. Fixed scope and a timeline you can plan around.",
    gets: [
      "Custom design and build",
      "An editor you can use without code",
      "Contact and lead capture",
      "Dashboards and admin tools if you need them",
      "A full handoff with documentation",
    ],
    time: "4 to 8 weeks",
  },
  {
    id: "mobile",
    code: "S-04",
    title: "A mobile app",
    lead: "One app that runs on both iPhone and Android, built to feel fast and natural.",
    gets: ["One app for iPhone and Android", "A design that feels native", "Preparation for the app stores", "Updates after launch"],
    time: "6 to 14 weeks",
  },
  {
    id: "tools",
    code: "S-05",
    title: "Internal tools and dashboards",
    lead: "Custom tools your team uses every day: dashboards, admin panels and workflow software built around how you actually work.",
    gets: ["Dashboards and reporting", "Admin tools and workflows", "The right access for each person on your team", "A full handoff with documentation"],
    time: "Scoped with you",
  },
  {
    id: "store",
    code: "S-06",
    title: "An online store",
    lead: "A fast online store built around your products, with checkout and the tools to run it day to day.",
    gets: ["A custom storefront design", "Product catalog and checkout", "Order management", "An editor you can use without code"],
    time: "Scoped with you",
  },
  {
    id: "rebuild",
    code: "S-07",
    title: "Rebuild existing software",
    lead: "Is your current software slow, outdated or hard to change? We modernise it carefully so your team can keep working.",
    gets: ["A review of what you have today", "A plan to move over safely", "A faster, easier-to-change rebuild", "A full handoff with documentation"],
    time: "Scoped with you",
  },
];
