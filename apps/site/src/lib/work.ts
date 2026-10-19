export type Status = "Live" | "No longer live" | "Client work";

export type CaseStudy = {
  slug: string;
  id: string;
  name: string;
  industry: string;
  status: Status;
  tagline: string;
  summary: string;
  img: string | null;
  url: string | null;
  label: string | null;
  challenge: string;
  built: string[];
  did: string;
};

export const WORK: CaseStudy[] = [
  {
    slug: "dealrdash",
    id: "C-01",
    name: "DealrDash",
    industry: "Car dealerships",
    status: "Live",
    tagline: "One dashboard to run a dealership.",
    summary: "Software that brings inventory, leads, deals and accounting into one place for independent dealerships in Canada and the US.",
    img: "/work/dealrdash.jpg",
    url: "https://www.dealrdash.com",
    label: "dealrdash.com",
    challenge:
      "Independent dealerships often juggle separate tools for inventory, leads, deal paperwork and accounting, and still need a website that stays up to date. We set out to put all of it in one place that a lean team can run.",
    built: [
      "A platform where each dealership gets its own space, with support for multiple locations",
      "Inventory, leads and deals together in one dashboard",
      "Deal documents, such as the bill of sale and forms, prepared inside the product",
      "A dealership website that stays in sync with the inventory",
      "A free plan so a dealership can start without a credit card",
    ],
    did: "Product design and full build",
  },
  {
    slug: "zavara-studio",
    id: "C-02",
    name: "Zavara Studio",
    industry: "Jewelry",
    status: "Live",
    tagline: "Jewelry content in minutes, not days.",
    summary: "An AI-first platform that helps jewelers create product visuals and manage their clients and orders.",
    img: "/work/zavara.jpg",
    url: "https://www.zavarastudio.com",
    label: "zavarastudio.com",
    challenge:
      "Jewelers can wait days for CAD renders, product photos and videos, while also keeping track of clients and orders. We built a platform where AI does the slow creative work in minutes.",
    built: [
      "AI-generated CAD renders, product photography, model shots and videos",
      "A design studio and a video studio built for jewelry",
      "A client portal and order management",
      "A product catalog",
    ],
    did: "AI product design and full build",
  },
  {
    slug: "halal-compass",
    id: "C-03",
    name: "Halal Compass",
    industry: "Community and food",
    status: "No longer live",
    tagline: "A guide to halal food and community places.",
    summary: "A consumer guide to finding halal restaurants, mosques and community events, on the web and on mobile.",
    img: "/work/halal.jpg",
    url: null,
    label: null,
    challenge:
      "Finding places that are genuinely halal, and trusting the listing, can be hard, especially in a new city. We built a guide people could search, with listings checked and backed by community reviews.",
    built: [
      "Search for halal restaurants, mosques and community events near you",
      "Verified listings with community reviews",
      "Location-aware results",
      "Web, mobile and the internal tools to run it, in one build",
      "Advertising space for local businesses",
    ],
    did: "Consumer product design and full build",
  },
  {
    slug: "client-websites",
    id: "C-04",
    name: "Client websites",
    industry: "Automotive and jewellery",
    status: "Client work",
    tagline: "Websites clients can run themselves.",
    summary: "Fast, custom websites for automotive and jewellery businesses, managed by the clients without touching code.",
    img: null,
    url: null,
    label: null,
    challenge:
      "Small businesses need a website that looks sharp and loads fast, without depending on a developer for every change. We build sites their teams can edit themselves.",
    built: [
      "Custom design and build",
      "A content editor the client uses without touching code",
      "Inventory display and lead capture forms for a dealership client",
      "Fast, search-friendly pages",
    ],
    did: "Design and build",
  },
];

export const caseBySlug = (slug: string) => WORK.find((w) => w.slug === slug);
