export class EmailError extends Error {
  constructor(err: String) {
    super(`Failed to send email: ${err}`);
  }
}

export async function sendEmail({
  from = "no-reply",
  to,
  subject,
  html,
}: {
  from?: string;
  to: string;
  subject: string;
  html: string;
}) {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${process.env.RESEND_KEY}`,
    },
    body: JSON.stringify({
      from: `Lift App <${from}@email.lift.elijahcobb.app>`,
      to: [to],
      subject,
      html,
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new EmailError(text);
  }
}
