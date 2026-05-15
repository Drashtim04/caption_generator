import "dotenv/config";
import cors from "cors";
import express from "express";
import multer from "multer";
import OpenAI from "openai";
import sharp from "sharp";

const PORT = Number(process.env.PORT || 8080);
const MAX_UPLOAD_MB = Number(process.env.MAX_UPLOAD_MB || 10);
const MAX_UPLOAD_BYTES = Math.max(1, MAX_UPLOAD_MB) * 1024 * 1024;
const GROQ_MODEL =
  process.env.GROQ_MODEL || "meta-llama/llama-4-scout-17b-16e-instruct";
const GROQ_FALLBACK_VISION_MODEL =
  process.env.GROQ_FALLBACK_VISION_MODEL ||
  "meta-llama/llama-4-scout-17b-16e-instruct";
const GROQ_API_KEY = process.env.GROQ_API_KEY || "";

if (!GROQ_API_KEY) {
  console.warn("Missing GROQ_API_KEY. Set it in backend/.env.");
}

const ai = GROQ_API_KEY
  ? new OpenAI({
      apiKey: GROQ_API_KEY,
      baseURL: "https://api.groq.com/openai/v1",
    })
  : null;

const app = express();

app.use(cors());
app.use(express.json({ limit: "2mb" }));

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_UPLOAD_BYTES },
  fileFilter: (_req, file, cb) => {
    if (!file.mimetype?.startsWith("image/")) {
      cb(new Error("Only image uploads are supported."));
      return;
    }
    cb(null, true);
  },
});

app.get("/health", (_req, res) => {
  res.json({ success: true, message: "Backend is healthy." });
});

app.post("/api/generate-captions", upload.single("image"), async (req, res) => {
  try {
    if (!ai) {
      res.status(500).json({
        success: false,
        message: "GROQ_API_KEY is not configured on the backend.",
      });
      return;
    }

    if (!req.file?.buffer) {
      res.status(400).json({
        success: false,
        message: "Missing image file. Send multipart/form-data with field name 'image'.",
      });
      return;
    }

    const normalizedImage = await toVisionSafeJpeg(req.file.buffer);
    const imageDataUrl = `data:image/jpeg;base64,${normalizedImage.toString("base64")}`;

    const completion = await createCaptionCompletion({
      ai,
      model: GROQ_MODEL,
      imageDataUrl,
    }).catch(async (error) => {
      const canFallback =
        GROQ_FALLBACK_VISION_MODEL &&
        GROQ_FALLBACK_VISION_MODEL !== GROQ_MODEL &&
        shouldRetryWithVisionFallback(error);

      if (!canFallback) throw error;

      return createCaptionCompletion({
        ai,
        model: GROQ_FALLBACK_VISION_MODEL,
        imageDataUrl,
      });
    });

    const raw = completion.choices?.[0]?.message?.content || "{}";
    const parsed = safeJsonParse(raw);
    const normalized = normalizeResponse(parsed);

    res.json({
      success: true,
      description: normalized.description,
      captions: normalized.captions,
      tags: normalized.tags,
      mood: normalized.mood,
    });
  } catch (error) {
    const message =
      error?.error?.message ||
      error?.message ||
      "Caption generation failed.";
    console.error("generate-captions error:", message);
    res.status(500).json({ success: false, message });
  }
});

app.use((err, _req, res, _next) => {
  const message = err?.message || "Request failed.";
  const status =
    message.toLowerCase().includes("file too large") ||
    message.toLowerCase().includes("only image uploads")
      ? 400
      : 500;
  res.status(status).json({ success: false, message });
});

app.listen(PORT, () => {
  console.log(`Caption backend running at http://localhost:${PORT}`);
});

async function toVisionSafeJpeg(input) {
  const maxBase64Bytes = 4 * 1024 * 1024 - 32 * 1024;
  let width = 1600;
  let quality = 85;

  for (let i = 0; i < 6; i += 1) {
    const output = await sharp(input)
      .rotate()
      .resize({
        width,
        height: width,
        fit: "inside",
        withoutEnlargement: true,
      })
      .jpeg({ quality, mozjpeg: true })
      .toBuffer();

    if (output.length <= maxBase64Bytes) {
      return output;
    }

    quality = Math.max(45, quality - 8);
    width = Math.max(900, Math.floor(width * 0.85));
  }

  throw new Error(
    "Image is too large after optimization. Please upload a smaller image."
  );
}

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch {
    const cleaned = value
      .replace(/^```json/i, "")
      .replace(/^```/i, "")
      .replace(/```$/i, "")
      .trim();
    try {
      return JSON.parse(cleaned);
    } catch {
      return {};
    }
  }
}

function normalizeResponse(data) {
  const description = asNonEmptyString(data?.description, "Image caption pack.");
  const captions = uniq(
    asStringArray(data?.captions).slice(0, 8),
    (s) => s.toLowerCase()
  );
  const tags = uniq(
    asStringArray(data?.tags)
      .map((tag) => (tag.startsWith("#") ? tag : `#${tag}`))
      .slice(0, 20),
    (s) => s.toLowerCase()
  );
  const mood = asNonEmptyString(data?.mood, "neutral");

  return {
    description,
    captions: captions.length
      ? captions
      : [
          "Just a good moment captured.",
          "Keeping it simple and real.",
          "Small frame, big feeling.",
          "No filter needed for this one.",
          "One photo, many memories.",
        ],
    tags: tags.length ? tags : ["#photo", "#moments", "#vibes"],
    mood,
  };
}

function asNonEmptyString(value, fallback) {
  if (typeof value !== "string") return fallback;
  const normalized = value.trim();
  return normalized || fallback;
}

function asStringArray(value) {
  if (!Array.isArray(value)) return [];
  return value
    .map((v) => String(v ?? "").trim())
    .filter((v) => v.length > 0);
}

function uniq(items, keyFn) {
  const seen = new Set();
  const out = [];
  for (const item of items) {
    const key = keyFn(item);
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(item);
  }
  return out;
}

async function createCaptionCompletion({ ai, model, imageDataUrl }) {
  return ai.chat.completions.create({
    model,
    temperature: 0.6,
    response_format: { type: "json_object" },
    max_completion_tokens: 700,
    messages: [
      {
        role: "system",
        content:
          "You generate social media caption packs from images. Return valid JSON only.",
      },
      {
        role: "user",
        content: [
          {
            type: "text",
            text: [
              "Analyze this image and return strict JSON with exactly these keys:",
              '{ "description": string, "captions": string[], "tags": string[], "mood": string }',
              "Rules:",
              "- description: one clear sentence.",
              "- captions: 5 unique captions, short to medium length.",
              "- tags: 10 to 14 items, each starting with '#'.",
              "- mood: 2 to 4 words.",
              "- No markdown, no extra keys.",
            ].join("\n"),
          },
          {
            type: "image_url",
            image_url: { url: imageDataUrl },
          },
        ],
      },
    ],
  });
}

function shouldRetryWithVisionFallback(error) {
  const message = String(error?.error?.message || error?.message || "").toLowerCase();
  return (
    message.includes("image") ||
    message.includes("vision") ||
    message.includes("does not support") ||
    message.includes("content must be a string") ||
    message.includes("invalid content type") ||
    message.includes("unsupported")
  );
}
