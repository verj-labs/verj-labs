export const CAL_URL = "https://cal.com/verj-labs/discovery-meeting";
export const EMAIL = "hello@verjlabs.com";
export const NEED_EVENT = "verj:need";

export type NeedId = "ai" | "product" | "web" | "mobile" | "tools" | "store" | "rebuild";

export type Need = {
  id: NeedId;
  label: string;
  short: string;
  blurb: string;
  time: string;
  weeks: string;
  icon: string[];
};

// Pixel drawings, 7 x 6.
export const NEEDS: Need[] = [
  {
    id: "ai",
    label: "AI for your business",
    short: "AI",
    blurb: "Put AI to work: answer questions from your own documents, automate repetitive tasks, generate content and search smarter.",
    time: "2 to 6 weeks",
    weeks: "2 to 6 weeks",
    icon: ["0001000", "0001000", "0111110", "0001000", "0101010", "1000001"],
  },
  {
    id: "product",
    label: "A new software product",
    short: "Product",
    blurb: "Have an idea for an app, a platform or an internal system? We take it from idea to a live product.",
    time: "6 to 16 weeks",
    weeks: "6 to 16 weeks",
    icon: ["1110111", "1010101", "1110111", "0000000", "1101011", "1101011"],
  },
  {
    id: "web",
    label: "A website or web platform",
    short: "Website",
    blurb: "A custom site or platform that looks sharp, loads fast and that you can edit yourself.",
    time: "4 to 8 weeks",
    weeks: "4 to 8 weeks",
    icon: ["1111111", "1000001", "1011101", "1000001", "1011101", "1111111"],
  },
  {
    id: "mobile",
    label: "A mobile app",
    short: "Mobile app",
    blurb: "One app that runs on both iPhone and Android.",
    time: "6 to 14 weeks",
    weeks: "6 to 14 weeks",
    icon: ["0011100", "0100010", "0101010", "0100010", "0101010", "0011100"],
  },
  {
    id: "tools",
    label: "Internal tools and dashboards",
    short: "Internal tools",
    blurb: "Custom dashboards, admin panels and workflow tools built around how your team actually works.",
    time: "Scoped with you",
    weeks: "Scoped with you",
    icon: ["0000001", "0000101", "0010101", "1010101", "1010101", "1111111"],
  },
  {
    id: "store",
    label: "An online store",
    short: "Online store",
    blurb: "A fast online store built around your products, with checkout and the tools to run it.",
    time: "Scoped with you",
    weeks: "Scoped with you",
    icon: ["0111110", "0100010", "1111111", "1000001", "1000001", "1111111"],
  },
  {
    id: "rebuild",
    label: "Rebuild existing software",
    short: "Rebuild",
    blurb: "Slow, outdated or hard to change? We modernise it carefully so your team can keep working.",
    time: "Scoped with you",
    weeks: "Scoped with you",
    icon: ["0111100", "1000010", "1000111", "1000010", "0100010", "0011100"],
  },
];

export const timeLabel = (time: string) => (/week/.test(time) ? `Typical timeline: ${time}` : `Timeline: ${time.toLowerCase()}`);

export const needById = (id?: string | null) => NEEDS.find((n) => n.id === id);
