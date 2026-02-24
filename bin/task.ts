// task.ts
import { parseArgs } from "jsr:@std/cli/parse-args";

const args = parseArgs(Deno.args);

const { ticket, target } = args;

if (!ticket || !target) {
  console.error("Usage: deno run --allow-read task.ts --ticket=<name> --target=<file>");
  Deno.exit(1);
}

const exitWith = (msg: string, code = 1) => {
  console.error(msg);
  Deno.exit(code);
};

try {

  // Check and read config file (only this scope)
  await Deno.stat(target).catch(() => { throw new Error(`Config file not found: ${target}`); });

  const cfgText = await Deno.readTextFile(target).catch((err) => { throw new Error(`Failed reading config ${target}: ${err.message}`); });

  let config;

  try {
    config = JSON.parse(cfgText);
  } catch (err) {
    throw new Error(`Invalid JSON in config ${target}: ${(err as Error).message}`);
  }

  const { HANDLE_URL, JOBS_DIR, MEDIA_ENDPOINT, VIEWER_ENDPOINT } = config;

  if (!JOBS_DIR) throw new Error(`JOBS_DIR is missing from config ${target}`);

  if (!HANDLE_URL) throw new Error(`HANDLE_URL is missing from config ${target}`);

  if (!MEDIA_ENDPOINT) throw new Error(`MEDIA_ENDPOINT is missing from config ${target}`);

  if (!VIEWER_ENDPOINT) throw new Error(`VIEWER_ENDPOINT is missing from config ${target}`);

  const jobFile = `${JOBS_DIR.replace(/\/+$/, "")}/${ticket}-se-list.txt`;

  const handleURL = HANDLE_URL.replace(/\/+$/, "");

  let endpoint = "";

  if (ticket.startsWith("DLTSIMAGES-")) {
    endpoint = VIEWER_ENDPOINT;
  } else if (ticket.startsWith("DLTSBOOKS-")) {
    endpoint = VIEWER_ENDPOINT;
  } else if (ticket.startsWith("DLTSAUDIO-")) {
    endpoint = MEDIA_ENDPOINT;
  }
  else if (ticket.startsWith("DLTSVIDEO-")) {
    endpoint = MEDIA_ENDPOINT;
  }
  else if (ticket.startsWith("HIDVL-")) {
    endpoint = MEDIA_ENDPOINT;
  }
  else {
    throw new Error(`unknown ticket type for ticket: ${ticket}`);
  }

  // Check and read job file (clear separate scope)
  await Deno.stat(jobFile).catch(() => { throw new Error(`Job file not found: ${jobFile}`); });

  // Simpler: read whole file and split lines (sensible unless file is huge)
  let jobText: string;

  try {
    jobText = await Deno.readTextFile(jobFile);
  } catch (err) {
    throw new Error(`Failed reading job file ${jobFile}: ${(err as Error).message}`);
  }

  // Echo each line
  const lines = jobText.split(/\r?\n/);

  // If file ends with newline, last element will be "" — keep or drop as you want
  for (const identifier of lines) {
    if (identifier === "") continue;
      // Fetch the endpoint with the XML document

      const noid = identifier.trim();
      console.log(`Processing noid: ${noid}`);
      // await fetch(`${handleURL}/id/handle/2333.1/${noid}`, options)
      //   .then(response => {
      //     if (!response.ok) {
      //       throw new Error(`Network response was not ok: ${response.status} - ${response.statusText}`);
      //     }
      //     return response.text();
      // })
      // .then(data => {
      //   console.log('Response from the server:', data);
      //   console.log(`https://sites.dlib.nyu.edu/media/api/v0/noid/${noid}/embed`);
      // })
      // .catch(error => {
      //   console.error('Error:', error);
      // })
  }

} catch (err) {
  // Print the real error so you can see what failed
  console.error("Error:", (err as Error).message);
  // optionally print stack for debugging:
  // console.error((err as Error).stack);
  Deno.exit(1);
}
