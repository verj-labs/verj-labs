export default function SecHead({ no, title, note }: { no: string; title: string; note: string }) {
  return (
    <div className="vh-sechead">
      <span className="vh-mono">[ {no} ]</span>
      <h2 className="vh-sechead-title">{title}</h2>
      <span className="vh-mono vh-sechead-note">{note}</span>
    </div>
  );
}
