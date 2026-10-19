import PixelStrip from "@/components/home/PixelStrip";

export default function PageHead({ code, title, lead }: { code: string; title: string; lead: string }) {
  return (
    <section className="vh-pagehead">
      <p className="vh-mono">[ {code} ]</p>
      <h1 className="vh-pagehead-title">{title}</h1>
      <p className="vh-pagehead-lead">{lead}</p>
      <PixelStrip className="vh-strip vh-strip-page" />
    </section>
  );
}
