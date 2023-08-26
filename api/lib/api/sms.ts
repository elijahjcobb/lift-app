export class SMSError extends Error {
  public constructor(message: string) {
    super(message);
    this.name = "SMSError";
  }
}

export function cleanPhoneNumber(number: string): string {
  let num = number.trim().replace(/\D/g, "");
  if (!num.startsWith("1")) num = "1" + num;
  num = "+" + num;
  return num;
}

export async function sendSMS({
  to,
  message,
}: {
  to: string;
  message: string;
}): Promise<void> {
  const data = new URLSearchParams();

  let num = to;
  if (num.startsWith("1")) num = "+" + num;
  else if (!num.startsWith("+1")) num = "+1" + num;

  data.append("To", num);
  data.append("From", "+18772270545");
  data.append("Body", message);

  const res = await fetch(
    "https://api.twilio.com/2010-04-01/Accounts/ACfed8b999ac7306e297252e47d28606ae/Messages.json",
    {
      method: "POST",
      body: data,
      headers: {
        Authorization: `Basic ${btoa(process.env.TWILIO_KEY ?? "")}`,
      },
    }
  );

  if (!res.ok) {
    const text = await res.text();
    throw new SMSError(text);
  }
}
